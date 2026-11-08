#!/usr/bin/env bash
#
# backup-diario-com-lock.sh - Backup diário com lock anti-concorrência
#
# Uso: backup-diario-com-lock.sh
#   Roda via cron diário. Impede execuções simultâneas com flock.
#
# Códigos de saída:
#   0 sucesso | 1 outra instância ativa | 2 erro genérico | 3 pré-requisito

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOCK_FILE="/var/lock/${SCRIPT_NAME%.sh}.lock"
readonly ORIGEM="/dados"
readonly DESTINO="/backup/diario"

log() {
    local nivel="$1"
    shift
    printf '%s [%s] %s[%d]: %s\n' "$(date '+%F %T')" "$nivel" "$SCRIPT_NAME" "$$" "$*" >&2
}
log_info()  { log INFO "$@"; }
log_erro()  { log ERRO "$@"; }

die() {
    local codigo="${2:-1}"
    log_erro "$1"
    exit "$codigo"
}

cleanup() {
    local codigo=$?
    [[ $codigo -eq 0 ]] || log_erro "finalizado com código $codigo"
}
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

main() {
    requer_comando tar
    requer_comando date
    requer_comando mkdir
    requer_comando flock

    [[ -d "$ORIGEM" ]] || die "origem não existe: $ORIGEM" 2
    [[ -r "$ORIGEM" ]] || die "sem leitura na origem: $ORIGEM" 2

    mkdir -p "$DESTINO"
    [[ -w "$DESTINO" ]] || die "sem escrita no destino: $DESTINO" 2

    # Lock não bloqueante - falha rápido se outra instância rodando
    exec 9> "$LOCK_FILE"
    if ! flock -n 9; then
        local pid_outro
        pid_outro=$(cat "$LOCK_FILE" 2>/dev/null || echo "?")
        die "outra instância ativa (PID: $pid_outro) - saindo" 1
    fi
    echo "$$" >&9

    local arquivo
    arquivo="backup-$(date '+%F').tar.gz"
    local destino_completo="${DESTINO}/${arquivo}"

    log_info "iniciando backup: $destino_completo"

    tar -czf "$destino_completo" "$ORIGEM"

    log_info "concluído: $destino_completo"
}

main "$@"