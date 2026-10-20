#!/usr/bin/env bash
#
# healthcheck-composto.sh - Healthcheck composto com múltiplas dependências
# Verifica HTTP endpoints, portas TCP e systemd service.
#
# Uso:
#   healthcheck-composto.sh [-j|--json] [-v|--verbose] [-t|--timeout S]
#                          [-r|--retries N] [-i|--interval S]
#                          [-c|--config ARQ] [--alerta] [-h|--help]
#
# Opções:
#   -j, --json          Saída JSON
#   -v, --verbose       Log detalhado
#   -t, --timeout S     Timeout por check (padrão: 10)
#   -r, --retries N     Tentativas (padrão: 3)
#   -i, --interval S    Intervalo entre retries (padrão: 2)
#   -c, --config ARQ    Arquivo de configuração YAML/JSON (padrão: healthcheck-config.yaml)
#   --alerta            Dispara alerta-webhook.sh se houver falha
#   -h, --help          Exibe ajuda
#
# Códigos de saída:
#   0 todos OK | 1 alguma falha | 2 uso incorreto | 3 pré-requisito

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
VERBOSE=0
TIMEOUT=10
RETRIES=3
INTERVAL=2
CONFIG_FILE="healthcheck-config.yaml"
DISPARA_ALERTA=0
ALERTA_CANAL="slack"
ALERTA_URL=""

log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG) [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$msg" ;;
        *) [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$msg" ;;
    esac
}
log_info() { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro() { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }
die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha (código $c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }
usage() { sed -n '3,24p' "$0" | sed 's/^# \{0,1\}//'; }

# --- Parse config YAML simples (requer yq ou python) ---
parse_config() {
    local arquivo="$1"
    [[ -f "$arquivo" ]] || die "config não encontrado: $arquivo" 1
    
    if command -v yq >/dev/null 2>&1; then
        yq -r '.app | to_entries | .[] | "\(.key)=\(.value)"' "$arquivo"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
import yaml, sys
with open('$arquivo') as f:
    data = yaml.safe_load(f)
for k, v in data.get('app', {}).items():
    print(f'{k}={v}')
"
    else
        die "yq ou python3 necessário para parsear YAML" 3
    fi
}

# --- Checks individuais ---
check_http() {
    local nome="$1" url="$2"
    local inicio fim duracao http_code
    local curl_opts=(-sf --max-time "$TIMEOUT" -w "\n%{http_code}\n%{time_total}")

    for attempt in $(seq 1 "$RETRIES"); do
        [[ "$VERBOSE" -eq 1 ]] && log_debug "$nome: tentativa $attempt"
        inicio=$(date +%s%3N)
        local saida
        saida=$(curl "${curl_opts[@]}" "$url" 2>/dev/null || true)
        fim=$(date +%s%3N)
        duracao=$(( fim - inicio ))
        http_code=$(echo "$saida" | tail -1)
        
        if [[ "$http_code" =~ ^2[0-9]{2}$ ]]; then
            jq -n --arg n "$nome" --arg t "http" --arg s "ok" --arg u "$url" --arg hc "$http_code" --argjson d "$duracao" --arg ts "$(date -Iseconds)" \
                '{nome: $n, tipo: $t, status: $s, url: $u, http_code: ($hc|tonumber), duracao_ms: $d, timestamp: $ts}'
            return 0
        fi
        [[ $attempt -lt $RETRIES ]] && sleep "$INTERVAL"
    done
    
    jq -n --arg n "$nome" --arg t "http" --arg s "fail" --arg u "$url" --arg hc "${http_code:-000}" --argjson d "$duracao" --arg e "HTTP $http_code após $RETRIES tentativas" --arg ts "$(date -Iseconds)" \
        '{nome: $n, tipo: $t, status: $s, url: $u, http_code: ($hc|tonumber), duracao_ms: $d, erro: $e, timestamp: $ts}'
    return 1
}

check_tcp() {
    local nome="$1" host="$2" port="$3"
    local nc_cmd
    command -v nc >/dev/null && nc_cmd="nc -z -w $TIMEOUT" || \
    command -v ncat >/dev/null && nc_cmd="ncat -z -w $TIMEOUT" || \
    nc_cmd="timeout $TIMEOUT bash -c \"cat < /dev/null > /dev/tcp/$host/$port\""
    
    for attempt in $(seq 1 "$RETRIES"); do
        [[ "$VERBOSE" -eq 1 ]] && log_debug "$nome: tentativa $attempt"
        local inicio
        inicio=$(date +%s%3N)
        if eval "$nc_cmd $host $port" >/dev/null 2>&1; then
            local fim
            fim=$(date +%s%3N)
            local duracao
            duracao=$(( fim - inicio ))
            jq -n --arg n "$nome" --arg t "tcp" --arg s "ok" --arg u "$host:$port" --argjson d "$duracao" --arg ts "$(date -Iseconds)" \
                '{nome: $n, tipo: $t, status: $s, url: $u, duracao_ms: $d, timestamp: $ts}'
            return 0
        fi
        local fim
        fim=$(date +%s%3N)
        local duracao
        duracao=$(( fim - inicio ))
        [[ $attempt -lt $RETRIES ]] && sleep "$INTERVAL"
    done
    
    jq -n --arg n "$nome" --arg t "tcp" --arg s "fail" --arg u "$host:$port" --argjson d "$duracao" --arg e "Conexão recusada após $RETRIES tentativas" --arg ts "$(date -Iseconds)" \
        '{nome: $n, tipo: $t, status: $s, url: $u, duracao_ms: $d, erro: $e, timestamp: $ts}'
    return 1
}

check_systemd() {
    local nome="$1" service="$2"
    local inicio
    inicio=$(date +%s%3N)
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        local fim
        fim=$(date +%s%3N)
        jq -n --arg n "$nome" --arg t "systemd" --arg s "ok" --arg u "$service" --argjson d $((fim-inicio)) --arg ts "$(date -Iseconds)" \
            '{nome: $n, tipo: $t, status: $s, url: $u, duracao_ms: $d, timestamp: $ts}'
        return 0
    else
        local estado
        estado=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
        local fim
        fim=$(date +%s%3N)
        jq -n --arg n "$nome" --arg t "systemd" --arg s "fail" --arg u "$service" --argjson d $((fim-inicio)) --arg e "Serviço $service: $estado" --arg ts "$(date -Iseconds)" \
            '{nome: $n, tipo: $t, status: $s, url: $u, duracao_ms: $d, erro: $e, timestamp: $ts}'
        return 1
    fi
}

# --- Envia alerta ---
envia_alerta() {
    local resultados_json="$1"
    local falhas
    falhas=$(echo "$resultados_json" | jq '[.[] | select(.status=="fail")] | length')
    [[ $falhas -eq 0 ]] && return 0
    
    local msg
    msg=$(echo "$resultados_json" | jq -r '.[] | select(.status=="fail") | "\(.nome) (\(.tipo)): \(.erro // .http_code)"' | paste -sd '; ')
    
    if command -v alerta-webhook.sh >/dev/null 2>&1; then
        alerta-webhook.sh -c "$ALERTA_CANAL" -u "$ALERTA_URL" -t "Healthcheck falhou: $CONFIG_FILE" -m "$msg" -s critical -l "config=$CONFIG_FILE" || log_aviso "falha ao enviar alerta"
    else
        log_aviso "alerta-webhook.sh não encontrado, pulando alerta"
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -t|--timeout) TIMEOUT="${2:-}"; shift 2 ;;
            -r|--retries) RETRIES="${2:-}"; shift 2 ;;
            -i|--interval) INTERVAL="${2:-}"; shift 2 ;;
            -c|--config) CONFIG_FILE="${2:-}"; shift 2 ;;
            --alerta) DISPARA_ALERTA=1; shift ;;
            --alerta-canal) ALERTA_CANAL="${2:-}"; shift 2 ;;
            --alerta-url) ALERTA_URL="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento: $1" 2 ;;
        esac
    done

    [[ "$TIMEOUT" =~ ^[0-9]+$ ]] && (( TIMEOUT > 0 )) || die "timeout: $TIMEOUT" 2
    [[ "$RETRIES" =~ ^[0-9]+$ ]] && (( RETRIES > 0 )) || die "retries: $RETRIES" 2
    [[ "$INTERVAL" =~ ^[0-9]+$ ]] && (( INTERVAL >= 0 )) || die "interval: $INTERVAL" 2

    requer_comando curl
    requer_comando jq
    command -v yq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 || die "yq ou python3 necessário" 3

    # Carrega config
    local config_vars
    config_vars=$(parse_config "$CONFIG_FILE")
    
    local health_endpoint ready_endpoint db_host db_port cache_host cache_port systemd_service
    eval "$config_vars"
    
    log_info "início (config=$CONFIG_FILE, alerta=$DISPARA_ALERTA)"

    local results="[]"
    local falhas=0

    # Executa checks
    [[ -n "$health_endpoint" ]] && { r=$(check_http "health" "$health_endpoint") || ((falhas++)); results=$(echo "$results" | jq -c --argjson x "$r" '. + [$x]'); }
    [[ -n "$ready_endpoint" ]] && { r=$(check_http "ready" "$ready_endpoint") || ((falhas++)); results=$(echo "$results" | jq -c --argjson x "$r" '. + [$x]'); }
    [[ -n "$db_host" && -n "$db_port" ]] && { r=$(check_tcp "database" "$db_host" "$db_port") || ((falhas++)); results=$(echo "$results" | jq -c --argjson x "$r" '. + [$x]'); }
    [[ -n "$cache_host" && -n "$cache_port" ]] && { r=$(check_tcp "cache" "$cache_host" "$cache_port") || ((falhas++)); results=$(echo "$results" | jq -c --argjson x "$r" '. + [$x]'); }
    [[ -n "$systemd_service" ]] && { r=$(check_systemd "systemd" "$systemd_service") || ((falhas++)); results=$(echo "$results" | jq -c --argjson x "$r" '. + [$x]'); }

    # Saída
    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        local ok
        ok=$(( 5 - falhas ))  # ajustar conforme checks habilitados
        jq -n --argjson total 5 --argjson ok "$ok" --argjson falhas "$falhas" --argjson checks "$results" --arg ts "$(date -Iseconds)" \
            '{timestamp: $ts, total: $total, ok: $ok, falhas: $falhas, verificacoes: $checks}'
    else
        echo "$results" | jq -r '.[] | "\(.nome) \(.status) \(.http_code // "") \(.duracao_ms)ms \(.erro // "")"' | while IFS= read -r line; do
            read -r n s hc d e <<< "$line"
            if [[ "$s" == "ok" ]]; then printf '\033[0;32m[OK]\033[0m  %s %s %sms\n' "$n" "$hc" "$d"; else printf '\033[0;31m[FALHA]\033[0m %s %sms - %s\n' "$n" "$d" "$e"; fi
        done
        log_info "Resumo: 5 verificações, $(( 5 - falhas )) OK, $falhas FALHA"
    fi

    [[ $DISPARA_ALERTA -eq 1 ]] && envia_alerta "$results"

    [[ $falhas -eq 0 ]] || exit 1
}

main "$@"