#!/usr/bin/env bash
#
# healthcheck-loop.sh - Healthcheck com coleta de incidente em falha
#
# Uso: healthcheck-loop.sh [-s SERVICOS] [-e ENDPOINTS] [-m MAX_CICLOS] [-i INTERVALO] [-h]
#
# Opções:
#   -s SERVICOS     Arquivo com serviços systemd (padrão: servicos.txt)
#   -e ENDPOINTS    Arquivo com endpoints HTTP (padrão: endpoints.txt)
#   -m MAX_CICLOS   Máximo de ciclos (padrão: 3)
#   -i INTERVALO    Intervalo entre ciclos em segundos (padrão: 30)
#   -h              Exibe ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

SERVICOS_FILE="servicos.txt"
ENDPOINTS_FILE="endpoints.txt"
MAX_CICLOS=3
INTERVALO=30

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

usage() { sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'; }

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s) SERVICOS_FILE="${2:-}"; shift 2 ;;
            -e) ENDPOINTS_FILE="${2:-}"; shift 2 ;;
            -m) MAX_CICLOS="${2:-}"; shift 2 ;;
            -i) INTERVALO="${2:-}"; shift 2 ;;
            -h) usage; exit 0 ;;
            *) die "Opção desconhecida: $1" 2 ;;
        esac
    done

    [[ "$MAX_CICLOS" =~ ^[0-9]+$ ]] || die "MAX_CICLOS deve ser número" 2
    [[ "$INTERVALO" =~ ^[0-9]+$ ]] || die "INTERVALO deve ser número" 2

    requer_comando sre-toolkit
    requer_comando jq
    requer_comando tar

    [[ -f "$SERVICOS_FILE" ]] || die "Arquivo de serviços não encontrado: $SERVICOS_FILE" 2
    [[ -f "$ENDPOINTS_FILE" ]] || die "Arquivo de endpoints não encontrado: $ENDPOINTS_FILE" 2

    log_info "início (servicos=$SERVICOS_FILE endpoints=$ENDPOINTS_FILE max_ciclos=$MAX_CICLOS intervalo=${INTERVALO}s)"

    echo "Iniciando healthcheck loop (máx $MAX_CICLOS ciclos, intervalo ${INTERVALO}s)..."

    local CICLO=0
    while (( CICLO < MAX_CICLOS )); do
        ((CICLO++))
        echo "=== Ciclo $CICLO/$MAX_CICLOS - $(date '+%F %T') ==="

        local json
        json=$(sre-toolkit health -j -s "$SERVICOS_FILE" -e "$ENDPOINTS_FILE" 2>/dev/null) || {
            log_erro "Falha ao executar healthcheck"
            sleep "$INTERVALO"
            continue
        }

        local fail
        fail=$(echo "$json" | jq -r '.fail // 0')

        if (( fail > 0 )); then
            local dir
            dir="/tmp/incidente-$(date +%F-%H%M%S)"
            echo "Falhas detectadas ($fail). Coletando incidente em $dir..."
            sre-toolkit incidente --coleta-completa --dir "$dir"
            echo "Incidente coletado. Compactando..."
            run tar -czf "${dir}.tar.gz" -C /tmp "$(basename "$dir")"
            echo "Arquivo: ${dir}.tar.gz"
        else
            echo "Todas verificações OK!"
        fi

        (( CICLO < MAX_CICLOS )) && sleep "$INTERVALO"
    done

    echo "Monitoramento finalizado."
    log_info "fim"
}

main "$@"