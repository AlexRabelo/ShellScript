#!/usr/bin/env bash
#
# alerta-webhook.sh - Envia alertas para múltiplos canais (Slack, Teams, Telegram, Email, Webhook genérico)
# Usado por outros scripts para notificar falhas, healthchecks, backup, etc.
#
# Uso:
#   alerta-webhook.sh [-c|--canal TIPO] [-u|--url URL] [-t|--titulo TEXTO]
#                    [-m|--mensagem TEXTO] [-s|--severidade NIVEL]
#                    [-l|--labels "k=v,k=v"] [-h|--help]
#
# Opções:
#   -c, --canal TIPO    Canal: slack, teams, telegram, email, webhook, stdout (padrão: stdout)
#   -u, --url URL       Webhook URL (obrigatório para slack/teams/telegram/webhook)
#   -t, --titulo TEXTO  Título do alerta
#   -m, --mensagem TEXTO Mensagem principal (suporta markdown)
#   -s, --severidade    Nível: info, warning, critical (padrão: warning)
#   -l, --labels        Labels extras: "servico=nginx,ambiente=prod"
#   -H, --header        Header extra para webhook: "Authorization: Bearer token"
#   -d, --dry-run       Mostra payload sem enviar
#   -h, --help          Exibe ajuda
#
# Variáveis de ambiente (alternativa às flags):
#   ALERT_WEBHOOK_URL, ALERT_SLACK_URL, ALERT_TEAMS_URL, ALERT_TELEGRAM_BOT_TOKEN, ALERT_TELEGRAM_CHAT_ID
#   ALERT_SMTP_HOST, ALERT_SMTP_PORT, ALERT_SMTP_USER, ALERT_SMTP_PASS, ALERT_EMAIL_FROM, ALERT_EMAIL_TO
#
# Códigos de saída:
#   0 enviado | 1 falha envio | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   alerta-webhook.sh -c slack -u "$SLACK_WEBHOOK" -t "Backup falhou" -m "Backup do /dados falhou às 02:30" -s critical
#   alerta-webhook.sh -c teams -u "$TEAMS_WEBHOOK" -t "Healthcheck" -m "API /health retornou 500"
#   alerta-webhook.sh -c telegram -t "Alerta" -m "Disco 95% cheio" -l "host=web01,disco=/"
#   alerta-webhook.sh -c webhook -u "https://meu-siem/api/alert" -H "Auth: Bearer xxx" -t "Evento" -m '{"custom": "json"}'

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

CANAL="stdout"
WEBHOOK_URL=""
TITULO="Alerta do sistema"
MENSAGEM=""
SEVERIDADE="warning"
LABELS=""
HEADERS_EXTRA=()
DRY_RUN=0

# Cores por severidade (para stdout)
declare -A CORES=(
    [info]="\033[0;34m"
    [warning]="\033[1;33m"
    [critical]="\033[0;31m"
    [reset]="\033[0m"
)

# Emojis por severidade
declare -A EMOJIS=(
    [info]="ℹ️"
    [warning]="⚠️"
    [critical]="🚨"
)

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG) [[ "$DRY_RUN" -eq 1 ]] && printf '%s\n' "$msg" ;;
        *) printf '%s\n' "$msg" ;;
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
usage() { sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'; }

# --- Formata labels para JSON ---
formata_labels_json() {
    local labels_str="$1"
    [[ -z "$labels_str" ]] && echo "{}" && return
    echo "$labels_str" | tr ',' '\n' | while IFS='=' read -r k v; do
        [[ -n "$k" ]] && printf '"%s": "%s",' "$k" "$v"
    done | sed 's/,$//' | awk '{print "{" $0 "}"}'
}

# --- Payload Slack ---
payload_slack() {
    local cor
    case "$SEVERIDADE" in
        info) cor="#36a64f" ;;
        warning) cor="#ff9900" ;;
        critical) cor="#ff0000" ;;
        *) cor="#808080" ;;
    esac
    
    # Build fields directly with jq from LABELS
    local fields
    if [[ -n "$LABELS" ]]; then
        fields=$(jq -n --arg labels "$LABELS" '
            ($labels | split(",") | map(split("=")) | map({title: .[0], value: .[1], short: true}))
        ')
    else
        fields='[]'
    fi
    
    jq -n \
        --arg titulo "$TITULO" \
        --arg mensagem "$MENSAGEM" \
        --arg severidade "$SEVERIDADE" \
        --arg cor "$cor" \
        --argjson fields "$fields" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg hostname "$(hostname)" \
        '{
            username: "SRE Bot",
            icon_emoji: ":warning:",
            attachments: [{
                color: $cor,
                title: $titulo,
                text: $mensagem,
                fields: $fields,
                footer: "Host: \($hostname) | Severidade: \($severidade)",
                ts: ($timestamp | fromdateiso8601)
            }]
        }'
}

# --- Payload Teams ---
payload_teams() {
    local cor
    case "$SEVERIDADE" in
        info) cor="0078D7" ;;
        warning) cor="FF9900" ;;
        critical) cor="FF0000" ;;
        *) cor="808080" ;;
    esac
    
    local facts
    if [[ -n "$LABELS" ]]; then
        facts=$(jq -n --arg labels "$LABELS" '
            ($labels | split(",") | map(split("=")) | map({name: .[0], value: .[1]}))
        ')
    else
        facts='[]'
    fi
    
    jq -n \
        --arg titulo "$TITULO" \
        --arg mensagem "$MENSAGEM" \
        --arg severidade "$SEVERIDADE" \
        --arg cor "$cor" \
        --argjson facts "$facts" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg hostname "$(hostname)" \
        '{
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            themeColor: $cor,
            summary: $titulo,
            sections: [{
                activityTitle: $titulo,
                activitySubtitle: "Severidade: \($severidade) | Host: \($hostname)",
                activityImage: "https://cdn-icons-png.flaticon.com/512/2967/2967234.png",
                text: $mensagem,
                facts: $facts,
                markdown: true
            }]
        }'
}

# --- Payload Telegram ---
payload_telegram() {
    local emoji
    emoji="${EMOJIS[$SEVERIDADE]:-⚠️}"
    local texto
    texto="*${emoji} ${TITULO}*\n\n${MENSAGEM}\n\n_Severidade: ${SEVERIDADE}_\n_Host: $(hostname)_\n_Tempo: $(date)_"
    
    if [[ -n "$LABELS" ]]; then
        texto+="\n\n*Labels:*"
        echo "$LABELS" | tr ',' '\n' | while IFS='=' read -r k v; do
            [[ -n "$k" ]] && texto+="\n\`${k}\`: \`${v}\`"
        done
    fi
    
    jq -n --arg chat_id "${ALERT_TELEGRAM_CHAT_ID:-}" --arg texto "$texto" --arg parse_mode "Markdown" \
        '{chat_id: $chat_id, text: $texto, parse_mode: $parse_mode}'
}

# --- Payload Email (sendmail/mail) ---
payload_email() {
    local assunto
    assunto="[${SEVERIDADE^^}] ${TITULO}"
    local corpo
    corpo="Severidade: ${SEVERIDADE}
Host: $(hostname)
Timestamp: $(date -Iseconds)
${LABELS:+Labels: ${LABELS}}

${MENSAGEM}
"
    printf 'Subject: %s\nTo: %s\nFrom: %s\nContent-Type: text/plain; charset=UTF-8\n\n%s' \
        "$assunto" "${ALERT_EMAIL_TO:-}" "${ALERT_EMAIL_FROM:-}" "$corpo"
}

# --- Payload Webhook genérico ---
payload_webhook() {
    local labels_json
    labels_json=$(formata_labels "$LABELS")
    
    jq -n \
        --arg titulo "$TITULO" \
        --arg mensagem "$MENSAGEM" \
        --arg severidade "$SEVERIDADE" \
        --arg labels "$labels_json" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg hostname "$(hostname)" \
        '{titulo: $titulo, mensagem: $mensagem, severidade: $severidade, labels: ($labels | split(",") | map(split("=")) | from_entries), timestamp: $timestamp, hostname: $hostname}'
}

# --- Envia via curl ---
envia_curl() {
    local url
    url="$1" payload="$2" content_type="${3:-application/json}"
    local curl_opts
    curl_opts=(-sf --max-time 10 -H "Content-Type: ${content_type}")
    
    for h in "${HEADERS_EXTRA[@]}"; do
        curl_opts+=(-H "$h")
    done
    
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_debug "[DRY-RUN] curl ${curl_opts[*]} -d '${payload}' ${url}"
        echo "$payload" | jq . 2>/dev/null || echo "$payload"
        return 0
    fi
    
    local resposta
    resposta=$(curl "${curl_opts[@]}" -d "$payload" "$url" 2>&1)
    local codigo=$?
    
    if [[ $codigo -eq 0 ]]; then
        log_info "Enviado com sucesso para $url"
        return 0
    else
        log_erro "Falha ao enviar para $url (código $codigo): $resposta"
        return 1
    fi
}

# --- Envia email ---
envia_email() {
    local payload
    payload=$(payload_email)
    
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_debug "[DRY-RUN] Email:"
        echo "$payload"
        return 0
    fi
    
    if command -v sendmail >/dev/null 2>&1; then
        echo "$payload" | sendmail -t
    elif command -v mail >/dev/null 2>&1; then
        echo "$payload" | mail -s "$(echo "$payload" | head -1 | cut -d: -f2-)" "${ALERT_EMAIL_TO:-}"
    else
        log_erro "sendmail/mail não encontrado"
        return 1
    fi
}

# --- Stdout ---
envia_stdout() {
    local cor
    cor="${CORES[$SEVERIDADE]:-}"
    local reset
    reset="${CORES[reset]}"
    local emoji
    emoji="${EMOJIS[$SEVERIDADE]:-}"
    
    printf '%b[%s] %s%b\n' "$cor" "$SEVERIDADE" "$emoji $TITULO" "$reset"
    printf 'Mensagem: %s\n' "$MENSAGEM"
    [[ -n "$LABELS" ]] && printf 'Labels: %s\n' "$LABELS"
    printf 'Host: %s | Tempo: %s\n' "$(hostname)" "$(date -Iseconds)"
    echo "---"
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--canal) CANAL="${2:-}"; shift 2 ;;
            -u|--url) WEBHOOK_URL="${2:-}"; shift 2 ;;
            -t|--titulo) TITULO="${2:-}"; shift 2 ;;
            -m|--mensagem) MENSAGEM="${2:-}"; shift 2 ;;
            -s|--severidade) SEVERIDADE="${2:-}"; shift 2 ;;
            -l|--labels) LABELS="${2:-}"; shift 2 ;;
            -H|--header) HEADERS_EXTRA+=("$2"); shift 2 ;;
            -d|--dry-run) DRY_RUN=1; shift ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento não esperado: $1" 2 ;;
        esac
    done

    # Fallback para variáveis de ambiente
    [[ -z "$WEBHOOK_URL" && "$CANAL" == "slack" ]] && WEBHOOK_URL="${ALERT_SLACK_URL:-}"
    [[ -z "$WEBHOOK_URL" && "$CANAL" == "teams" ]] && WEBHOOK_URL="${ALERT_TEAMS_URL:-}"
    [[ -z "$WEBHOOK_URL" && "$CANAL" == "telegram" ]] && WEBHOOK_URL="https://api.telegram.org/bot${ALERT_TELEGRAM_BOT_TOKEN:-}/sendMessage"
    [[ -z "$WEBHOOK_URL" && "$CANAL" == "webhook" ]] && WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"

    [[ -n "$TITULO" ]] || die "título obrigatório (-t)" 2
    [[ -n "$MENSAGEM" ]] || die "mensagem obrigatória (-m)" 2
    [[ "$SEVERIDADE" =~ ^(info|warning|critical)$ ]] || die "severidade inválida: $SEVERIDADE (use info|warning|critical)" 2
    [[ "$CANAL" =~ ^(slack|teams|telegram|email|webhook|stdout)$ ]] || die "canal inválido: $CANAL" 2

    # Valida URL para canais que precisam
    if [[ "$CANAL" =~ ^(slack|teams|telegram|webhook)$ && -z "$WEBHOOK_URL" ]]; then
        die "URL obrigatória para canal $CANAL (use -u ou variável de ambiente)" 2
    fi

    log_info "enviando alerta (canal=$CANAL, severidade=$SEVERIDADE, dry-run=$DRY_RUN)"

    case "$CANAL" in
        slack)
            requer_comando curl
            requer_comando jq
            envia_curl "$WEBHOOK_URL" "$(payload_slack)"
            ;;
        teams)
            requer_comando curl
            requer_comando jq
            envia_curl "$WEBHOOK_URL" "$(payload_teams)"
            ;;
        telegram)
            requer_comando curl
            requer_comando jq
            [[ -n "${ALERT_TELEGRAM_CHAT_ID:-}" ]] || die "ALERT_TELEGRAM_CHAT_ID não definido" 3
            envia_curl "$WEBHOOK_URL" "$(payload_telegram)"
            ;;
        email)
            envia_email
            ;;
        webhook)
            requer_comando curl
            requer_comando jq
            envia_curl "$WEBHOOK_URL" "$(payload_webhook)"
            ;;
        stdout)
            envia_stdout
            ;;
    esac

    log_info "alerta processado"
}

main "$@"