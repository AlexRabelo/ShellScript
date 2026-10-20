#!/usr/bin/env bash
#
# lib/log.sh - biblioteca universal de log com timestamps e níveis.
#
# Uso:
#   source lib/log.sh
#   log_info "Mensagem normal"
#   log_sucesso "Sucesso"
#   log_aviso "Atenção"
#   log_erro "Algo falhou"
#   die "Erro fatal" 2

# Cores ANSI (desativadas se não for terminal interativo ou se NO_COLOR estiver definida)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    readonly COR_RESET="\033[0m"
    readonly COR_AZUL="\033[1;34m"
    readonly COR_AMARELO="\033[1;33m"
    readonly COR_VERMELHO="\033[1;31m"
    readonly COR_VERDE="\033[1;32m"
else
    readonly COR_RESET=""
    readonly COR_AZUL=""
    readonly COR_AMARELO=""
    readonly COR_VERMELHO=""
    readonly COR_VERDE=""
fi

_log_base() {
    local nivel="$1"
    local cor="$2"
    shift 2
    local ts
    ts=$(date '+%F %T')
    printf "%s ${cor}[%-7s]${COR_RESET} %s\n" "$ts" "$nivel" "$*"
}

log_info()    { _log_base "INFO"   "$COR_AZUL"     "$@"; }
log_sucesso() { _log_base "SUCESSO" "$COR_VERDE"    "$@"; }
log_aviso()   { _log_base "AVISO"  "$COR_AMARELO"  "$@" >&2; }
log_erro()    { _log_base "ERRO"   "$COR_VERMELHO" "$@" >&2; }

die() {
    local msg="$1"
    local cod="${2:-1}"
    log_erro "$msg"
    exit "$cod"
}