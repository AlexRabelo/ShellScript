#!/usr/bin/env bash
#
# monitora-saude.sh - Monitora saúde e alerta se thresholds excedidos
#
# Uso: monitora-saude.sh [-c CPU] [-r RAM] [-d DISK] [-i INTERVALO] [-h]
#
# Opções:
#   -c CPU      Threshold CPU % (padrão: 80)
#   -r RAM      Threshold RAM % (padrão: 90)
#   -d DISK     Threshold Disco % (padrão: 90)
#   -i INTERVALO  Intervalo em segundos (padrão: 60)
#   -h          Exibe ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

THRESHOLD_CPU=80
THRESHOLD_RAM=90
THRESHOLD_DISK=90
INTERVALO=60

log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        *) printf '%s\n' "$msg" ;;
    esac
}
log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; (( c != 0 )) && log_erro "terminou com falha (código $c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando obrigatório: $1" 3; }

usage() { sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; }

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c) THRESHOLD_CPU="${2:-}"; shift 2 ;;
            -r) THRESHOLD_RAM="${2:-}"; shift 2 ;;
            -d) THRESHOLD_DISK="${2:-}"; shift 2 ;;
            -i) INTERVALO="${2:-}"; shift 2 ;;
            -h) usage; exit 0 ;;
            *) die "Opção desconhecida: $1" 2 ;;
        esac
    done

    [[ "$THRESHOLD_CPU" =~ ^[0-9]+$ ]] || die "CPU threshold deve ser número" 2
    [[ "$THRESHOLD_RAM" =~ ^[0-9]+$ ]] || die "RAM threshold deve ser número" 2
    [[ "$THRESHOLD_DISK" =~ ^[0-9]+$ ]] || die "DISK threshold deve ser número" 2
    [[ "$INTERVALO" =~ ^[0-9]+$ ]] || die "Intervalo deve ser número" 2

    requer_comando sre-toolkit
    requer_comando jq

    log_info "início (cpu>${THRESHOLD_CPU}% ram>${THRESHOLD_RAM}% disk>${THRESHOLD_DISK}% intervalo=${INTERVALO}s)"

    echo "Iniciando monitoramento (CPU>${THRESHOLD_CPU}%, RAM>${THRESHOLD_RAM}%, DISK>${THRESHOLD_DISK}%)..."
    echo "Pressione Ctrl+C para parar"
    echo

    while true; do
        local json
        json=$(sre-toolkit saude -j 2>/dev/null) || { log_erro "Falha ao obter saúde"; sleep "$INTERVALO"; continue; }

        local cpu ram disk
        cpu=$(echo "$json" | jq -r '.cpu.uso_percentual // 0')
        ram=$(echo "$json" | jq -r '.memoria.uso_percentual // 0')
        disk=$(echo "$json" | jq -r '.disco[0].uso_percentual // 0')

        local alerta=0
        (( cpu > THRESHOLD_CPU )) && { echo "[$(date '+%F %T')] ALERTA: CPU em ${cpu}%"; alerta=1; }
        (( ram > THRESHOLD_RAM )) && { echo "[$(date '+%F %T')] ALERTA: RAM em ${ram}%"; alerta=1; }
        (( disk > THRESHOLD_DISK )) && { echo "[$(date '+%F %T')] ALERTA: Disco em ${disk}%"; alerta=1; }

        if (( alerta == 0 )); then
            echo "[$(date '+%F %T')] OK - CPU:${cpu}% RAM:${ram}% DISK:${disk}%"
        fi

        sleep "$INTERVALO"
    done
}

main "$@"