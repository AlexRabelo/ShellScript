#!/usr/bin/env bash
# monitora-timers.sh - Monitora timers systemd e gera relatório JSON
#
# Uso:
#   monitora-timers.sh [-j|--json] [-a|--alerta] [-f|--falhas-apenas]
#
# Opções:
#   -j, --json         Saída em JSON (padrão: texto)
#   -a, --alerta       Sai com código 1 se houver falhas
#   -f, --falhas-apenas Mostra somente timers com falhas
#   -h, --help         Exibe ajuda
#
# Códigos de saída:
#   0 OK | 1 falha detectada | 2 uso incorreto

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
ALERTA=0
FALHAS_APENAS=0

log() {
    local nivel="$1"
    shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

log_info() { log INFO "$@"; }

die() { local c="${2:-1}"; log "ERRO" "$1"; exit "$c"; }

usage() { sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//' ; }

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -a|--alerta) ALERTA=1; shift ;;
            -f|--falhas-apenas) FALHAS_APENAS=1; shift ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    command -v systemctl > /dev/null 2>&1 || die "systemctl não encontrado" 3

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        command -v jq > /dev/null 2>&1 || die "jq necessário para saída JSON" 3
    fi

    log_info "início (json=$JSON_OUTPUT, alerta=$ALERTA)"

    local timers_json="[]"
    local falhas=0

    # Lista timers ativos - parseia saída tabular do systemctl
    while IFS= read -r linha; do
        [[ -z "$linha" ]] && continue
        # Formato: NEXT LEFT LAST PASSED UNIT ACTIVATES
        # Exemplo: Tue 2026-10-13 22:26:33 -03 1h 11min Mon 2026-10-12 17:54:17 -03 - man-db.timer man-db.service
        local next_str unit service
        next_str=$(echo "$linha" | awk '{print $1, $2, $3, $4}')
        unit=$(echo "$linha" | awk 'END {print $(NF-1)}')
        service=$(echo "$linha" | awk 'END {print $NF}')
        
        # Pula cabeçalho
        [[ "$unit" == "UNIT" || "$unit" == "timer" ]] && continue

        local ativo_ok=true
        local status_serv
        status_serv=$(systemctl is-failed "$service" 2>/dev/null || echo "inactive")
        local falhou=false
        [[ "$status_serv" == "failed" ]] && falhou=true && ((falhas++))

        [[ "$FALHAS_APENAS" -eq 1 && "$falhou" == false ]] && continue

        local proxima="$next_str"

        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            local obj
            obj=$(jq -n \
                --arg timer "$unit" \
                --arg service "$service" \
                --arg proxima "$proxima" \
                --argjson ativo "$ativo_ok" \
                --argjson falhou "$falhou" \
                '{timer: $timer, service: $service, proxima_execucao: $proxima, ativo: $ativo, falhou_ultima: $falhou}')
            timers_json=$(echo "$timers_json" | jq -c --argjson o "$obj" '. + [$o]')
        else
            printf 'Timer: %s\n' "$unit"
            printf '  Serviço: %s\n' "$service"
            printf '  Ativo: %s\n' "yes"
            printf '  Falhou: %s\n' "$falhou"
            echo
        fi
    done < <(systemctl list-timers --all --no-legend 2>/dev/null | head -100)

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n --argjson timers "$timers_json" --arg timestamp "$(date -Iseconds)" --argjson falhas "$falhas" \
            '{timestamp: $timestamp, timers: $timers, falhas: $falhas}'
    else
        local total_timers
        total_timers=$(echo "$timers_json" | jq length 2>/dev/null || echo 0)
        log_info "total: timers=$total_timers, falhas=$falhas"
    fi

    [[ $falhas -eq 0 ]] || exit 1
    exit 0
}

main "$@"