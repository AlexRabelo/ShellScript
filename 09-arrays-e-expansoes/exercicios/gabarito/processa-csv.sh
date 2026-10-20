#!/usr/bin/env bash
#
# processa-csv.sh - Processa CSV de servidores com arrays associativos
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   processa-csv.sh [-f FUNCAO] [-l LOCALIDADE] [-j] [ARQUIVO_CSV]
#
# Opções:
#   -h, --help     Exibe esta ajuda
#   -v, --verbose  Modo verboso
#   -n, --dry-run  Simula execução
#   -f FUNCAO      Filtra por função específica
#   -l LOCALIDADE  Filtra por localidade específica
#   -j             Saída em formato JSON
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto / argumentos inválidos
#   3  Pré-requisito ausente (awk, etc.)
#   4  Erro de permissão
#
# Exemplo:
#   processa-csv.sh -f frontend servidores.csv
#   processa-csv.sh -l rj -j servidores.csv
#
# Dependências:
#   - bash 4+
#   - awk
#   - jq (para saída JSON)
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
OUTPUT_JSON=0
FILTRO_FUNCAO=""
FILTRO_LOCALIDADE=""

log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO "$@" >&2; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
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

main() {
    # Processa opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -j|--json) OUTPUT_JSON=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -f|--funcao)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -f" 2
                FILTRO_FUNCAO="$2"; shift 2 ;;
            -l|--localidade)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -l" 2
                FILTRO_LOCALIDADE="$2"; shift 2 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    # Define arquivo CSV (padrão ou argumento)
    local csv_file="${1:-servidores.csv}"
    [[ -r "$csv_file" ]] || die "não é possível ler o arquivo CSV: $csv_file" 1

    requer_comando awk
    requer_comando printf

    log_info "início (csv=$csv_file, filtro_funcao='$FILTRO_FUNCAO', filtro_localidade='$FILTRO_LOCALIDADE', json=$OUTPUT_JSON)"

    # Arrays associativos para agregação
    declare -A cont_funcao      # contagem por função
    declare -A cont_localidade  # contagem por localidade
    declare -A soma_memoria     # soma de memória por localidade (GB)
    declare -A hosts_status     # lista de hosts por status

    # Processa CSV (pula cabeçalho)
    {
        read -r _  # ignora cabeçalho
        while IFS=',' read -r hostname funcao status localidade memoria_gb; do
            # Remove espaços em branco
            hostname="$(echo -n "$hostname" | xargs)"
            funcao="$(echo -n "$funcao" | xargs)"
            status="$(echo -n "$status" | xargs)"
            localidade="$(echo -n "$localidade" | xargs)"
            memoria_gb="$(echo -n "$memoria_gb" | xargs)"

            # Aplica filtros se especificados
            [[ -n "$FILTRO_FUNCAO" && "$funcao" != "$FILTRO_FUNCAO" ]] && continue
            [[ -n "$FILTRO_LOCALIDADE" && "$localidade" != "$FILTRO_LOCALIDADE" ]] && continue

            # Agrega dados
            ((cont_funcao["$funcao"]++))
            ((cont_localidade["$localidade"]++))
            ((soma_memoria["$localidade"]+=memoria_gb))
            hosts_status["$status"]+="${hosts_status[$status]:+ }$hostname"
        done
    } < "$csv_file"

    # Saída
    if (( OUTPUT_JSON )); then
        # Constrói objeto JSON com jq
        local json_funcao="" json_localidade="" json_memoria="" json_status=""
        
        # Funções
        for funcao in "${!cont_funcao[@]}"; do
            json_funcao+=$(printf ',"%s":%d' "$funcao" "${cont_funcao[$funcao]}")
        done
        json_funcao="{${json_funcao#,}}"

        # Localidades
        for localidade in "${!cont_localidade[@]}"; do
            json_localidade+=$(printf ',"%s":{cont:%d,memoria_gb:%d}' "$localidade" "${cont_localidade[$localidade]}" "${soma_memoria[$localidade]}")
        done
        json_localidade="{${json_localidade#,}}"

        # Status
        for status in "${!hosts_status[@]}"; do
            json_status+=$(printf ',"%s":"%s"' "$status" "${hosts_status[$status]}")
        done
        json_status="{${json_status#,}}"

        # Output final
        printf '{"funcoes":%s,"localidades":%s,"status":%s}\n' "$json_funcao" "$json_localidade" "$json_status" | jq .
    else
        # Saída legível
        echo "=== Relatório de Servidores ==="
        echo "Arquivo: $csv_file"
        echo

        echo "Contagem por função:"
        for funcao in "${!cont_funcao[@]}"; do
            [[ -z "$FILTRO_FUNCAO" || "$funcao" == "$FILTRO_FUNCAO" ]] && printf "  %-12s: %d\n" "$funcao" "${cont_funcao[$funcao]}"
        done
        echo

        echo "Contagem e memória por localidade:"
        for localidade in "${!cont_localidade[@]}"; do
            [[ -z "$FILTRO_LOCALIDADE" || "$localidade" == "$FILTRO_LOCALIDADE" ]] && printf "  %-10s: %d servidores, %d GB RAM\n" "$localidade" "${cont_localidade[$localidade]}" "${soma_memoria[$localidade]}"
        done
        echo

        echo "Hosts por status:"
        for status in "${!hosts_status[@]}"; do
            printf "  %-8s: %s\n" "$status" "${hosts_status[$status]}"
        done
    fi

    log_info "fim"
}

main "$@"