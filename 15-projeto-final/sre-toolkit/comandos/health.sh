#!/usr/bin/env bash
#
# comandos/health.sh - Healthcheck de serviços e endpoints
#
# Uso: sre-toolkit health [-j|--json] [-t|--timeout S] [-s|--servicos ARQ] [-e|--endpoints ARQ] [-h|--help]

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"
source "${LIB_DIR}/util.sh"

JSON_OUTPUT=0
TIMEOUT=5
ARQ_SERVICOS="servicos.txt"
ARQ_ENDPOINTS="endpoints.txt"

usage() {
    cat <<EOF
health - Healthcheck de serviços e endpoints

Uso: sre-toolkit health [-j|--json] [-t|--timeout S] [-s|--servicos ARQ] [-e|--endpoints ARQ] [-h|--help]

Opções:
  -j, --json       Saída JSON
  -t, --timeout S  Timeout HTTP em segundos (padrão: 5)
  -s, --servicos ARQ  Arquivo com serviços systemd (padrão: servicos.txt)
  -e, --endpoints ARQ  Arquivo com endpoints HTTP (padrão: endpoints.txt)
  -h, --help       Exibe ajuda
EOF
}

verifica_servico() {
    local servico="$1"
    if systemctl is-active --quiet "$servico" 2>/dev/null; then
        echo "ok"
        return 0
    else
        echo "fail"
        return 1
    fi
}

verifica_http() {
    local url="$1"
    if curl -sf --max-time "$TIMEOUT" -o /dev/null "$url" 2>/dev/null; then
        echo "ok"
        return 0
    else
        echo "fail"
        return 1
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -t|--timeout) TIMEOUT="${2:-}"; shift 2 ;;
            -s|--servicos) ARQ_SERVICOS="${2:-}"; shift 2 ;;
            -e|--endpoints) ARQ_ENDPOINTS="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) log_erro "Opção desconhecida: $1"; usage >&2; exit 2 ;;
        esac
    done

    valida_numero "$TIMEOUT" "timeout" || exit 2

    log_info "início (timeout=$TIMEOUT, servicos=$ARQ_SERVICOS, endpoints=$ARQ_ENDPOINTS)"

    local servicos=() endpoints=()
    mapfile -t servicos < <(grep -v '^\s*#' "$ARQ_SERVICOS" 2>/dev/null | grep -v '^\s*$' || echo "")
    mapfile -t endpoints < <(grep -v '^\s*#' "$ARQ_ENDPOINTS" 2>/dev/null | grep -v '^\s*$' || echo "")

    local total=0 ok=0 fail=0
    local results="[]"

    for svc in "${servicos[@]}"; do
        [[ -z "$svc" ]] && continue
        ((total++))
        if verifica_servico "$svc"; then
            ((ok++))
        else
            ((fail++))
        fi
        if (( JSON_OUTPUT == 1 )); then
            results=$(echo "$results" | jq -c --arg n "$svc" --arg s "$(verifica_servico "$svc")" '. + [{nome: $n, tipo: "systemd", status: $s}]')
        fi
    done

    for ep in "${endpoints[@]}"; do
        [[ -z "$ep" ]] && continue
        ((total++))
        if verifica_http "$ep"; then
            ((ok++))
        else
            ((fail++))
        fi
        if (( JSON_OUTPUT == 1 )); then
            results=$(echo "$results" | jq -c --arg u "$ep" --arg s "$(verifica_http "$ep")" '. + [{url: $u, tipo: "http", status: $s}]')
        fi
    done

    if (( JSON_OUTPUT == 1 )); then
        jq -n --argjson total "$total" --argjson ok "$ok" --argjson fail "$fail" --argjson results "$results" --arg ts "$(timestamp_iso)" \
            '{timestamp: $ts, total: $total, ok: $ok, fail: $fail, verificacoes: $results}'
    else
        echo "=== HEALTH CHECK ==="
        echo "Total verificações: $total"
        echo "OK: $ok"
        echo "FALHA: $fail"
        echo
        if [[ $fail -gt 0 ]]; then
            echo "Verificações com falha:"
            [[ ${#servicos[@]} -gt 0 ]] && echo "Serviços:" && for svc in "${servicos[@]}"; do [[ -n "$svc" ]] && verifica_servico "$svc" >/dev/null || echo "  $svc"; done
            [[ ${#endpoints[@]} -gt 0 ]] && echo "Endpoints:" && for ep in "${endpoints[@]}"; do [[ -n "$ep" ]] && verifica_http "$ep" >/dev/null || echo "  $ep"; done
        fi
    fi

    log_info "fim"
}

main "$@"