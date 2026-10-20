#!/usr/bin/env bash
#
# lib/log.sh - biblioteca universal de log com timestamps e níveis.
#
# Uso em outros scripts:
#   source "${SCRIPT_DIR}/lib/log.sh"
#   log_info "Mensagem normal"
#   log_aviso "Atenção"
#   log_erro "Algo falhou"
#   die "Erro fatal" 2

# Cores ANSI (desativadas se não for terminal interativo ou se NO_COLOR estiver definida)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    COR_RESET="\033[0m"
    COR_AZUL="\033[1;34m"
    COR_AMARELO="\033[1;33m"
    COR_VERMELHO="\033[1;31m"
    COR_VERDE="\033[1;32m"
else
    COR_RESET=""
    COR_AZUL=""
    COR_AMARELO=""
    COR_VERMELHO=""
    COR_VERDE=""
fi

log() {
    local nivel="$1"
    local cor="$2"
    shift 2
    local ts
    ts=$(date '+%F %T')
    printf "%s ${cor}[%-5s]${COR_RESET} %s\n" "$ts" "$nivel" "$*"
}

log_info()    { log "INFO"  "$COR_AZUL"     "$@"; }
log_sucesso() { log "OK"    "$COR_VERDE"    "$@"; }
log_aviso()   { log "AVISO" "$COR_AMARELO"  "$@" >&2; }
log_erro()    { log "ERRO"  "$COR_VERMELHO" "$@" >&2; }

die() {
    local msg="$1"
    local cod="${2:-1}"
    log_erro "$msg"
    exit "$cod"
}