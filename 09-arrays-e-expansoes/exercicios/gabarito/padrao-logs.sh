#!/usr/bin/env bash
#
# padrao-logs.sh - Padroniza logs de diversos formatos
#
# Uso: ./padrao-logs.sh [-j] [-t] [-F CAMPO] [-f FORMATO] [ARQUIVO_DE_LOG]
#
# Converte logs de diversos formatos para padrão unificado (JSON ou texto)
# usando arrays associativos para mapeamento de campos.
#
# Formatos suportados:
#   nginx/apache: $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
#   aplicação:    TIMESTAMP [LEVEL] MESSAGE
#
# Exemplo:
#   ./padrao-logs.sh -f nginx acesso.log
#   ./padrao-logs.sh -f aplicacao log.txt -j | jq .
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

OUTPUT_JSON=0
OUTPUT_TEXTO=1  # padrão
CAMPO_FILTRO=""  # vazio = todos os campos
FORMATO_DETECTAR=""  # vazio = auto-detectar

log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg
    msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO "$@" >&2; }

die() {
    local msg="$1"
    local codigo
    codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

cleanup() {
    local codigo=$?
    if [[ $codigo -eq 0 ]]; then
        log_info "terminou com sucesso"
    else
        log_erro "terminou com falha (código ${codigo})"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

usage() {
    sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'
}

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

# Funções de parsing por formato
parse_nginx_log() {
    local linha="$1"
    # Formato: $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
    if [[ "$linha" =~ ^([^[:space:]]+)\ ([^[:space:]]+)\ \[([^\]]+)\]\ \"([^\"]*)\"\ ([^[:space:]]+)\ ([^[:space:]]+)\ \"([^\"]*)\"\ \"([^\"]*)\"$ ]]; then
        declare -A campos=(
            [timestamp]="${BASH_REMATCH[3]}"
            [nivel]="INFO"  # nginx não tem nível, assume INFO
            [mensagem]="${BASH_REMATCH[4]}"  # request line
            [servico]="nginx"
            [status]="${BASH_REMATCH[5]}"
            [tamanho]="${BASH_REMATCH[6]}"
            [referer]="${BASH_REMATCH[7]}"
            [user_agent]="${BASH_REMATCH[8]}"
            [client_ip]="${BASH_REMATCH[1]}"
        )
        # Retorna como string JSON simples
        printf '{"timestamp":"%s","nivel":"%s","mensagem":"%s","servico":"%s","status":"%s","tamanho":"%s","referer":"%s","user_agent":"%s","client_ip":"%s"}' \
            "${campos[timestamp]}" "${campos[nivel]}" "${campos[mensagem]}" "${campos[servico]}" "${campos[status]}" "${campos[tamanho]}" "${campos[referer]}" "${campos[user_agent]}" "${campos[client_ip]}"
    else
        return 1  # não corresponde ao formato
    fi
}

parse_aplicacao_log() {
    local linha="$1"
    # Formato: TIMESTAMP [LEVEL] MESSAGE
    if [[ "$linha" =~ ^([^[:space:]]+[[:space:]][^[:space:]]+)\ [[[:space:]]*([^]]+)[[:space:]]*]\ (.*)$ ]]; then
        declare -A campos=(
            [timestamp]="${BASH_REMATCH[1]}"
            [nivel]="${BASH_REMATCH[2]}"
            [mensagem]="${BASH_REMATCH[3]}"
            [servico]="aplicacao"
            [status]="0"
            [tamanho]="0"
            [referer]=""
            [user_agent]=""
            [client_ip]=""
        )
        printf '{"timestamp":"%s","nivel":"%s","mensagem":"%s","servico":"%s","status":"%s","tamanho":"%s","referer":"%s","user_agent":"%s","client_ip":"%s"}' \
            "${campos[timestamp]}" "${campos[nivel]}" "${campos[mensagem]}" "${campos[servico]}" "${campos[status]}" "${campos[tamanho]}" "${campos[referer]}" "${campos[user_agent]}" "${campos[client_ip]}"
    else
        return 1
    fi
}

main() {
    # Processa opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -j|--json) OUTPUT_JSON=1; OUTPUT_TEXTO=0; shift ;;
            -t|--texto) OUTPUT_JSON=0; OUTPUT_TEXTO=1; shift ;;
            -F|--campo)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -F" 2
                CAMPO_FILTRO="$2"; shift 2 ;;
            -f|--formato)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -f" 2
                FORMATO_DETECTAR="$2"; shift 2 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    # Define arquivo de log (padrão ou argumento)
    local log_file
    log_file="${1:-/var/log/nginx/access.log}"
    [[ -r "$log_file" ]] || die "não é possível ler o arquivo de log: $log_file" 1

    requer_comando awk || true  # não é fatal para modo texto

    log_info "início (log=$log_file, json=$OUTPUT_JSON, texto=$OUTPUT_TEXTO, campo='$CAMPO_FILTRO', formato='$FORMATO_DETECTAR')"

    local linha_num=0
    while IFS= read -r linha || [[ -n "$linha" ]]; do
        (( linha_num++ ))
        [[ -z "$linha" ]] && continue  # ignora linhas vazias
        
        local json_linha=""
        local sucesso=0
        
        # Tenta parsers conforme formato especificado ou auto-detecção
        if [[ -n "$FORMATO_DETECTAR" ]]; then
            case "$FORMATO_DETECTAR" in
                nginx) json_linha=$(parse_nginx_log "$linha") && sucesso=1 ;;
                aplicacao) json_linha=$(parse_aplicacao_log "$linha") && sucesso=1 ;;
                *) die "formato não suportado: $FORMATO_DETECTAR" 2 ;;
            esac
        else
            # Auto-detecção: tenta nginx primeiro, depois aplicacao
            json_linha=$(parse_nginx_log "$linha") && sucesso=1
            if (( ! sucesso )); then
                json_linha=$(parse_aplicacao_log "$linha") && sucesso=1
            fi
        fi
        
        if (( sucesso )); then
            # Filtra por campo se especificado
            if [[ -n "$CAMPO_FILTRO" ]]; then
                # Extrai o valor do campo do JSON simples
                local valor_campo
                valor_campo=$(echo "$json_linha" | sed -n "s/.*\"$CAMPO_FILTRO\":\"\([^\"]*\)\".*/\1/p")
                if [[ -n "$valor_campo" ]]; then
                    if (( OUTPUT_JSON )); then
                        printf '%s\n' "$json_linha"
                    else
                        printf '[%s] %s: %s\n' "$(echo "$json_linha" | sed -n 's/.*"timestamp":"\([^"]*\)".*/\1/p')" "$CAMPO_FILTRO" "$valor_campo"
                    fi
                fi
            else
                # Output completo
                if (( OUTPUT_JSON )); then
                    printf '%s\n' "$json_linha"
                else
                    # Formato legível: timestamp [nivel] mensagem (servico:status)
                    local timestamp nivel mensagem servico status
                    timestamp=$(echo "$json_linha" | sed -n 's/.*"timestamp":"\([^"]*\)".*/\1/p')
                    nivel=$(echo "$json_linha" | sed -n 's/.*"nivel":"\([^"]*\)".*/\1/p')
                    mensagem=$(echo "$json_linha" | sed -n 's/.*"mensagem":"\([^"]*\)".*/\1/p')
                    servico=$(echo "$json_linha" | sed -n 's/.*"servico":"\([^"]*\)".*/\1/p')
                    status=$(echo "$json_linha" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')
                    printf '[%s] [%s] %s (%s:%s)\n' "$timestamp" "$nivel" "$mensagem" "$servico" "$status"
                fi
            fi
        else
            # Linha não pôde ser parseada - opcionalmente mostra como aviso
            (( VERBOSE )) && log_aviso "linha $linha_num não pôde ser parseada: ${linha:0:50}..."
        fi
    done < "$log_file"

    log_info "fim (processadas $linha_num linhas)"
}

main "$@"