#!/usr/bin/env bash
#
# checa-disco.sh - alerta baseado no uso de disco.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   checa-disco.sh
#
# Verifica o uso do disco raíz e exibe alerta baseado em limites:
# - >= 90%: CRÍTICO (exit 2)
# - >= 80%: AVISO (exit 1)
# - < 80%: OK (exit 0)
#
# Exemplo:
#   checa-disco.sh
#
# =============================================================================

set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

# --- Funções de Log ----------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

# --- Utilidades --------------------------------------------------------------
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

    # Verifica pré-requisitos
    requer_comando df
    requer_comando awk

    USO=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

    if (( USO >= 90 )); then
        echo "CRÍTICO: Disco em ${USO}%!" >&2
        log_erro "Uso crítico de disco: ${USO}%"
        exit 2
    elif (( USO >= 80 )); then
        echo "AVISO: Disco em ${USO}%."
        log_aviso "Uso alto de disco: ${USO}%"
        exit 1
    else
        echo "OK: Disco em ${USO}%."
        log_info "Uso normal de disco: ${USO}%"
        exit 0
    fi
}

main "$@"