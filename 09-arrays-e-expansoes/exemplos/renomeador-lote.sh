#!/usr/bin/env bash
#
# renomeador-lote.sh - renomeia arquivos em lote usando expansão de parâmetros.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   renomeador-lote.sh DIRETORIO PADRAO SUBSTITUICAO
#
# Renomeia arquivos em um diretório substituindo um padrão por outro.
# Usa expansão de parâmetros nativa do Bash (sem sed/awk externos).
#
# Exemplo:
#   renomeador-lote.sh /tmp/teste .log .txt
#   renomeador-lote.sh . backup_ ""
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"
DRY_RUN=0
VERBOSE=0

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

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

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

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] $*"
        return 0
    else
        log_debug "executando: $*"
        "$@"
    fi
}

usage() {
    sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    # Validação de argumentos vai aqui
    # Exemplo: [[ $# -eq 2 ]] || { usage >&2; die "forneça exatamente 2 argumentos" 2; }

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE)"

    # Lógica principal do script vai aqui
    # Exemplo:
    # for arg in "$@"; do
    #     log_info "Processando: $arg"
    # done

    [[ $# -eq 3 ]] || { usage >&2; die "forneça exatamente 3 argumentos (diretorio padrao substituicao)" 2; }

    local diretorio="$1"
    local padrao="$2"
    local substituicao="$3"

    [[ -d "$diretorio" ]] || die "diretório não encontrado: $diretorio" 1
    [[ -r "$diretorio" ]] || die "sem permissão de leitura no diretório: $diretorio" 1
    [[ -w "$diretorio" ]] || die "sem permissão de escrita no diretório: $diretorio" 1

    echo "=== Renomeador em Lote ==="
    echo "Diretório: $diretorio"
    echo "Padrão: '$padrao' → '$substituicao'"
    echo

    local contador=0
    local arquivos_encontrados=()

    # Encontra arquivos que contêm o padrão
    for arquivo in "$diretorio"/*"$padrao"*; do
        [[ -e "$arquivo" ]] || continue
        arquivos_encontrados+=("$arquivo")
    done

    if [[ ${#arquivos_encontrados[@]} -eq 0 ]]; then
        log_aviso "Nenhum arquivo encontrado com o padrão: $padrao"
        exit 0
    fi

    echo "Arquivos encontrados: ${#arquivos_encontrados[@]}"
    echo

    for arquivo in "${arquivos_encontrados[@]}"; do
        # Obtém apenas o nome do arquivo (basename)
        local nome_arquivo
        nome_arquivo="${arquivo##*/}"
        local dir_arquivo
        dir_arquivo="${arquivo%/*}"

        # Substitui o padrão usando expansão de parâmetros
        local novo_nome
        novo_nome="${nome_arquivo//$padrao/$substituicao}"

        # Se o nome não mudou, pula
        if [[ "$nome_arquivo" == "$novo_nome" ]]; then
            log_debug "Sem alteração para: $nome_arquivo"
            continue
        fi

        local novo_caminho="$dir_arquivo/$novo_nome"

        echo "Renomeando: $nome_arquivo → $novo_nome"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "[DRY-RUN] mv \"$arquivo\" \"$novo_caminho\""
        else
            mv "$arquivo" "$novo_caminho"
            ((contador++))
        fi
    done

    echo
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] $contador arquivo(s) seriam renomeados"
    else
        log_info "$contador arquivo(s) renomeado(s) com sucesso"
    fi

    log_info "fim"
}

main "$@"