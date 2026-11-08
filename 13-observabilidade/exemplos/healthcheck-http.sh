#!/usr/bin/env bash
#
# healthcheck-http.sh - Healthcheck HTTP/TCP avançado com retry, timeout e métricas
# Verifica endpoints HTTP/HTTPS e portas TCP, gera saída JSON para Prometheus/Grafana.
#
# Uso:
#   healthcheck-http.sh [-j|--json] [-v|--verbose] [-t|--timeout S]
#                      [-r|--retries N] [-i|--interval S]
#                      [-H|--header "K: V"]... URL [URL...]
#
# Opções:
#   -j, --json          Saída JSON (padrão: texto)
#   -v, --verbose       Log detalhado por tentativa
#   -t, --timeout S     Timeout total por request (padrão: 10)
#   -r, --retries N     Tentativas antes de falhar (padrão: 3)
#   -i, --interval S    Intervalo entre retries em segundos (padrão: 2)
#   -H, --header "K: V" Header HTTP extra (pode repetir)
#   -h, --help          Exibe ajuda
#
# Códigos de saída:
#   0 todos OK | 1 alguma falha | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   healthcheck-http.sh https://api.exemplo.com/health
#   healthcheck-http.sh -j -r 5 -t 15 https://api.exemplo.com/health https://app.exemplo.com/status
#   healthcheck-http.sh -H "Authorization: Bearer token" https://api.exemplo.com/private
#   healthcheck-http.sh tcp://db.exemplo.com:5432  # Verifica porta TCP

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
VERBOSE=0
TIMEOUT=10
RETRIES=3
INTERVAL=2
HEADERS=()
URLS=()

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      if (( VERBOSE == 1 )); then printf '%s\n' "$msg"; fi ;;
        *)          if (( JSON_OUTPUT == 0 )); then printf '%s\n' "$msg"; fi ;;
    esac
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

# --- Limpeza -----------------------------------------------------------------
cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "terminou com falha (código $c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM
trap 'log_erro "erro linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades --------------------------------------------------------------
requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando obrigatório: $1" 3; }

usage() { sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'; }

# Detecta tipo de URL
parse_url() {
    local url="$1"
    if [[ "$url" =~ ^tcp://([^:]+):([0-9]+)$ ]]; then
        echo "tcp ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    elif [[ "$url" =~ ^https?:// ]]; then
        echo "http $url"
    else
        die "URL inválida: $url (use http://, https:// ou tcp://host:porta)" 2
    fi
}

# Healthcheck HTTP
check_http() {
    local url="$1"
    local inicio fim duracao http_code saida erro
    local curl_opts=(-sf --max-time "$TIMEOUT" -w "\n%{http_code}\n%{time_total}\n%{size_download}")

    for h in "${HEADERS[@]}"; do
        curl_opts+=(-H "$h")
    done

    for attempt in $(seq 1 "$RETRIES"); do
        [[ "$VERBOSE" -eq 1 ]] && log_debug "Tentativa $attempt/$RETRIES: $url"
        
        inicio=$(date +%s%3N)
        saida=$(curl "${curl_opts[@]}" "$url" 2>/dev/null || true)
        fim=$(date +%s%3N)
        duracao=$(( fim - inicio ))

http_code=$(echo "$saida" | tail -3 | head -1)
        time_total=$(echo "$saida" | tail -2 | head -1)
        size_download=$(echo "$saida" | tail -1)
        # corpo=$(echo "$saida" | head -n -3)  # não usado no momento

        if [[ "$http_code" =~ ^2[0-9]{2}$ ]]; then
            local resultado
            resultado=$(jq -n \
                --arg url "$url" \
                --arg status "ok" \
                --arg http_code "$http_code" \
                --argjson duracao_ms "$duracao" \
                --argjson time_total "$time_total" \
                --argjson size "$size_download" \
                --arg attempt "$attempt" \
                --arg timestamp "$(date -Iseconds)" \
                '{url: $url, tipo: "http", status: $status, http_code: ($http_code|tonumber), duracao_ms: $duracao_ms, time_total: ($time_total|tonumber), size_bytes: ($size|tonumber), tentativa: ($attempt|tonumber), timestamp: $timestamp}')
            echo "$resultado"
            return 0
        fi

        [[ "$VERBOSE" -eq 1 ]] && log_aviso "Falha tentativa $attempt: HTTP $http_code"
        [[ $attempt -lt $RETRIES ]] && sleep "$INTERVAL"
    done

    local resultado
    resultado=$(jq -n \
        --arg url "$url" \
        --arg status "fail" \
        --arg http_code "${http_code:-000}" \
        --argjson duracao_ms "$duracao" \
        --arg erro "HTTP ${http_code:-timeout/erro} após $RETRIES tentativas" \
        --arg timestamp "$(date -Iseconds)" \
        '{url: $url, tipo: "http", status: $status, http_code: ($http_code|tonumber), duracao_ms: $duracao_ms, erro: $erro, timestamp: $timestamp}')
    echo "$resultado"
    return 1
}

# Healthcheck TCP
check_tcp() {
    local host="$1" porta="$2"
    local inicio fim duracao
    local nc_cmd

    if command -v nc >/dev/null 2>&1; then
        nc_cmd="nc -z -w $TIMEOUT"
    elif command -v ncat >/dev/null 2>&1; then
        nc_cmd="ncat -z -w $TIMEOUT"
    elif command -v timeout >/dev/null 2>&1 && command -v bash >/dev/null 2>&1; then
        nc_cmd="timeout $TIMEOUT bash -c \"cat < /dev/null > /dev/tcp/$host/$porta\""
    else
        die "nc/ncat/timeout não encontrado para TCP check" 3
    fi

    for attempt in $(seq 1 "$RETRIES"); do
        [[ "$VERBOSE" -eq 1 ]] && log_debug "TCP tentativa $attempt/$RETRIES: $host:$porta"
        
        inicio=$(date +%s%3N)
        if eval "$nc_cmd $host $porta" >/dev/null 2>&1; then
            fim=$(date +%s%3N)
            duracao=$(( fim - inicio ))
            local resultado
            resultado=$(jq -n \
                --arg url "tcp://$host:$porta" \
                --arg status "ok" \
                --argjson duracao_ms "$duracao" \
                --arg attempt "$attempt" \
                --arg timestamp "$(date -Iseconds)" \
                '{url: $url, tipo: "tcp", status: $status, duracao_ms: $duracao_ms, tentativa: ($attempt|tonumber), timestamp: $timestamp}')
            echo "$resultado"
            return 0
        fi
        
        fim=$(date +%s%3N)
        duracao=$(( fim - inicio ))
        [[ "$VERBOSE" -eq 1 ]] && log_aviso "TCP falha tentativa $attempt: $host:$porta"
        [[ $attempt -lt $RETRIES ]] && sleep "$INTERVAL"
    done

    local resultado
    resultado=$(jq -n \
        --arg url "tcp://$host:$porta" \
        --arg status "fail" \
        --argjson duracao_ms "$duracao" \
        --arg erro "Conexão recusada/timeout após $RETRIES tentativas" \
        --arg timestamp "$(date -Iseconds)" \
        '{url: $url, tipo: "tcp", status: $status, duracao_ms: $duracao_ms, erro: $erro, timestamp: $timestamp}')
    echo "$resultado"
    return 1
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -t|--timeout) TIMEOUT="${2:-}"; shift 2 ;;
            -r|--retries) RETRIES="${2:-}"; shift 2 ;;
            -i|--interval) INTERVAL="${2:-}"; shift 2 ;;
            -H|--header) HEADERS+=("$2"); shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) URLS+=("$1"); shift ;;
        esac
    done

    [[ ${#URLS[@]} -gt 0 ]] || { usage >&2; die "pelo menos 1 URL obrigatória" 2; }
if [[ "$TIMEOUT" =~ ^[0-9]+$ ]] && (( TIMEOUT > 0 )); then
        :
    else
        die "timeout inválido: $TIMEOUT" 2
    fi
    if [[ "$RETRIES" =~ ^[0-9]+$ ]] && (( RETRIES > 0 )); then
        :
    else
        die "retries inválido: $RETRIES" 2
    fi
    if [[ "$INTERVAL" =~ ^[0-9]+$ ]] && (( INTERVAL >= 0 )); then
        :
    else
        die "interval inválido: $INTERVAL" 2
    fi

    requer_comando curl
    [[ "$JSON_OUTPUT" -eq 1 ]] && requer_comando jq

    log_info "início (urls=${#URLS[@]}, timeout=${TIMEOUT}s, retries=$RETRIES, interval=${INTERVAL}s)"

    local results="[]"
    local falhas=0

    for url in "${URLS[@]}"; do
        local parsed tipo alvo
        parsed=$(parse_url "$url")
        read -r tipo alvo <<< "$parsed"

        local result
        if [[ "$tipo" == "http" ]]; then
            result=$(check_http "$alvo") || falhas=$((falhas+1))
        else
            read -r _ host porta <<< "$alvo"
            result=$(check_tcp "$host" "$porta") || falhas=$((falhas+1))
        fi

        results=$(echo "$results" | jq -c --argjson r "$result" '. + [$r]')
    done

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        local ok=$(( ${#URLS[@]} - falhas ))
        jq -n --argjson total "${#URLS[@]}" --argjson ok "$ok" --argjson falhas "$falhas" --argjson checks "$results" --arg ts "$(date -Iseconds)" \
            '{timestamp: $ts, total: $total, ok: $ok, falhas: $falhas, verificacoes: $checks}'
    else
        echo "$results" | jq -r '.[] | "\(.url) \(.status) \(.http_code // "") \(.duracao_ms)ms \(.erro // "")"' | while IFS= read -r line; do
            local u s c d e
            read -r u s c d e <<< "$line"
            if [[ "$s" == "ok" ]]; then
                printf '\033[0;32m[OK]\033[0m  %s %s %sms\n' "$u" "$c" "$d"
            else
                printf '\033[0;31m[FALHA]\033[0m %s %sms - %s\n' "$u" "$d" "$e"
            fi
        done
        log_info "Resumo: ${#URLS[@]} verificações, $(( ${#URLS[@]} - falhas )) OK, $falhas FALHA"
    fi

    [[ $falhas -eq 0 ]] || exit 1
}

main "$@"