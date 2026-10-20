#!/usr/bin/env bash
#
# recebe-alerta.handler.sh - Handler HTTP para Alertmanager (usado por socat/systemd)
# Recebe POST JSON, parseia alertas, roteia por severidade, deduplica.
#
# Uso (via socat):
#   socat TCP-LISTEN:9093,reuseaddr,fork SYSTEM:"/caminho/recebe-alerta.handler.sh"
#
# Ou via systemd socket activation (recebe-alerta.socket + recebe-alerta@.service)
#
# Variáveis de ambiente:
#   ALERT_DEDUP_DIR=/tmp/alert-dedup  (diretório para deduplicação, TTL 5min)
#   ALERT_DEFAULT_CANAL=slack
#   ALERT_SLACK_URL, ALERT_TEAMS_URL, ALERT_TELEGRAM_BOT_TOKEN, ALERT_TELEGRAM_CHAT_ID
#   ALERT_WEBHOOK_URL

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"
readonly DEDUP_DIR
DEDUP_DIR="${ALERT_DEDUP_DIR:-/tmp/alert-dedup}"
readonly _DEDUP_TTL=300  # 5 minutos

log() {
    local n="$1"
    shift
    local m
    m="$(date '+%F %T') [$n] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$m" >> "$LOG_FILE" 2>/dev/null || true
    case "$n" in
        ERRO|AVISO) printf '%s\n' "$m" >&2 ;;
        *) printf '%s\n' "$m" ;;
    esac
}
log_info() { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro() { log ERRO "$@"; }
die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }

# --- Deduplicação ---
dedup_check() {
    local key="$1"
    local file
    file="${DEDUP_DIR}/${key//\//_}"
    mkdir -p "$DEDUP_DIR"
    
    # Limpa arquivos antigos
    find "$DEDUP_DIR" -type f -mmin +5 -delete 2>/dev/null || true
    
    if [[ -f "$file" ]]; then
        return 1  # Já processado recentemente
    fi
    
    touch "$file"
    return 0  # Novo, processa
}

# --- Parse Alertmanager JSON ---
parse_alertmanager() {
    local json="$1"
    # Extrai array alerts
    echo "$json" | jq -c '.alerts[]? // empty' | while IFS= read -r alert; do
local alertname severity instance job summary description
        alertname=$(echo "$alert" | jq -r '.labels.alertname // "unknown"')
        severity=$(echo "$alert" | jq -r '.labels.severity // "warning"')
        instance=$(echo "$alert" | jq -r '.labels.instance // "unknown"')
        job=$(echo "$alert" | jq -r '.labels.job // "unknown"')
        summary=$(echo "$alert" | jq -r '.annotations.summary // ""')
        description=$(echo "$alert" | jq -r '.annotations.description // ""')
        
        # Chave de deduplicação
        local dedup_key
        dedup_key="${alertname}|${instance}|${severity}"
        
        if dedup_check "$dedup_key"; then
            # Novo alerta - processa
            local msg
            msg="[${severity^^}] ${alertname} em ${instance} (job: ${job})"
            [[ -n "$summary" ]] && msg+=" - ${summary}"
            [[ -n "$description" ]] && msg+=" | ${description}"
            
            # Determina canal por severidade
            local canal
            canal="${ALERT_DEFAULT_CANAL:-slack}"
            local url=""
            case "$severity" in
                critical) canal="telegram"; url="${ALERT_TELEGRAM_BOT_TOKEN:+https://api.telegram.org/bot${ALERT_TELEGRAM_BOT_TOKEN}/sendMessage}" ;;
                warning) canal="slack"; url="${ALERT_SLACK_URL:-}" ;;
                info) canal="stdout"; url="" ;;
            esac
            
            # Chama alerta-webhook.sh se disponível
            if command -v alerta-webhook.sh >/dev/null 2>&1; then
                alerta-webhook.sh -c "$canal" -u "$url" -t "$msg" -m "$description" -s "$severity" -l "alertname=$alertname,instance=$instance,job=$job" || log_aviso "falha ao enviar alerta"
            else
                log_aviso "alerta-webhook.sh não encontrado"
                printf '%s\n' "$msg"
            fi
            
            log_info "alerta processado: $dedup_key"
        else
            log_info "alerta duplicado ignorado: $dedup_key"
        fi
    done
}

# --- Healthcheck endpoint ---
healthcheck() {
    printf 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 27\r\n\r\n{"status":"healthy"}\r\n'
}

# --- Main HTTP handler ---
main() {
    # Lê request HTTP (simplificado para socat)
    local request_line headers body=""
    IFS= read -r request_line
    [[ "$request_line" =~ ^GET\ /health ]] && { healthcheck; exit 0; }
    [[ "$request_line" =~ ^POST\ / ]] || { printf 'HTTP/1.1 404 Not Found\r\n\r\n'; exit 1; }
    
    # Lê headers
    while IFS= read -r line; do
        line="${line%$'\r'}"
        [[ -z "$line" ]] && break
        headers+="$line"$'\n'
    done
    
    # Content-Length
    local content_length=0
    if echo "$headers" | grep -qi '^content-length:'; then
        content_length=$(echo "$headers" | grep -i '^content-length:' | sed 's/.*: *//' | tr -d '\r')
    fi
    
    # Lê body
    if [[ $content_length -gt 0 ]]; then
        body=$(dd bs=1 count="$content_length" 2>/dev/null || cat)
    else
        body=$(cat)
    fi
    
    # Processa JSON
    if echo "$body" | jq -e '.alerts' >/dev/null 2>&1; then
        parse_alertmanager "$body"
        printf 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 18\r\n\r\n{"status":"ok"}\r\n'
    else
        printf 'HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nContent-Length: 27\r\n\r\n{"error":"invalid json"}\r\n'
        exit 1
    fi
}

main