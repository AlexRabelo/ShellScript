#!/usr/bin/env bash
#
# lib/log.sh - Biblioteca de logging padronizada para sre-toolkit

# Níveis: DEBUG, INFO, AVISO, ERRO
# Variáveis: LOG_FILE, VERBOSE, JSON_OUTPUT (opcional)

log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "${LOG_FILE:-/tmp/${SCRIPT_NAME}.log}" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      (( ${VERBOSE:-0} == 1 )) && printf '%s\n' "$msg" ;;
        *)          (( ${JSON_OUTPUT:-0} == 0 )) && printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }