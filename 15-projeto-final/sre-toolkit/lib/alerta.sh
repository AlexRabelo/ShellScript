#!/usr/bin/env bash
#
# lib/alerta.sh - Biblioteca de alertas (Slack, Teams, Telegram, Webhook, stdout)

# Variáveis de ambiente esperadas:
# ALERT_SLACK_URL, ALERT_TEAMS_URL, ALERT_TELEGRAM_BOT_TOKEN, ALERT_TELEGRAM_CHAT_ID
# ALERT_WEBHOOK_URL, ALERT_EMAIL_TO, ALERT_EMAIL_FROM

alerta_enviar() {
    local canal
    canal="$1" titulo="$2" mensagem="$3" severidade="${4:-warning}" labels="${5:-}"
    local url=""
    
    case "$canal" in
        slack) url="${ALERT_SLACK_URL:-}" ;;
        teams) url="${ALERT_TEAMS_URL:-}" ;;
        telegram) url="https://api.telegram.org/bot${ALERT_TELEGRAM_BOT_TOKEN:-}/sendMessage" ;;
        webhook) url="${ALERT_WEBHOOK_URL:-}" ;;
        stdout) url="" ;;
        *) log_erro "Canal inválido: $canal"; return 2 ;;
    esac
    
    [[ "$canal" != "stdout" && -z "$url" ]] && { log_erro "URL não configurada para canal: $canal"; return 2; }
    
    local payload
    payload=$(alerta_gera_payload "$canal" "$titulo" "$mensagem" "$severidade" "$labels")
    
    if [[ "$canal" == "stdout" ]]; then
        echo "$payload" | jq . 2>/dev/null || echo "$payload"
        return 0
    fi
    
    alerta_envia_curl "$url" "$payload" "$canal"
}

alerta_gera_payload() {
    local canal="$1" titulo="$2" mensagem="$3" severidade="$4" labels="$5"
    local cor emoji
    
    case "$severidade" in
        info) cor="#36a64f"; emoji="ℹ️" ;;
        warning) cor="#ff9900"; emoji="⚠️" ;;
        critical) cor="#ff0000"; emoji="🚨" ;;
        *) cor="#808080"; emoji="🔔" ;;
    esac
    
    local labels_json
    labels_json=$(jq -n --arg l "$labels" '($l | split(",") | map(split("=")) | map({name: .[0], value: .[1]}))')
    
    case "$canal" in
        slack)
            jq -n --arg t "$titulo" --arg m "$mensagem" --arg s "$severidade" --arg c "$cor" \
                --argjson fields "$labels_json" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg hn "$(hostname)" \
                '{username:"SRE Toolkit",icon_emoji:":warning:",attachments:[{color:$c,title:$t,text:$m,fields:$fields,footer:"Host: \($hn) | \($s)",ts:($ts|fromdateiso8601)}]}'
            ;;
        teams)
            jq -n --arg t "$titulo" --arg m "$mensagem" --arg s "$severidade" --arg c "$cor" \
                --argjson facts "$labels_json" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg hn "$(hostname)" \
                '{"@type":"MessageCard","@context":"http://schema.org/extensions","themeColor":$c,"summary":$t,"sections":[{"activityTitle":$t,"activitySubtitle":"Severidade: \($s) | Host: \($hn)","text":$m,"facts":$facts,"markdown":true}]}'
            ;;
        telegram)
            local txt
            txt="*${emoji:-⚠️} ${titulo}*\n\n${mensagem}\n\n_Severidade: ${severidade}_\n_Host: $(hostname)_"
            [[ -n "$labels" ]] && txt+="\n\n*Labels:*\n$(echo "$labels" | tr ',' '\n' | sed 's/=/` = `/; s/^/`/; s/$/`/')"
            jq -n --arg chat_id "${ALERT_TELEGRAM_CHAT_ID:-}" --arg text "$txt" --arg parse_mode "Markdown" '{chat_id:$chat_id,text:$text,parse_mode:$parse_mode}'
            ;;
        webhook)
            jq -n --arg t "$titulo" --arg m "$mensagem" --arg s "$severidade" --argjson labels "$labels_json" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg hn "$(hostname)" \
                '{titulo:$t,mensagem:$m,severidade:$s,labels:$labels,timestamp:$ts,hostname:$hn}'
            ;;
        *)
            jq -n --arg t "$titulo" --arg m "$mensagem" --arg s "$severidade" --argjson labels "$labels_json" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg hn "$(hostname)" \
                '{titulo:$t,mensagem:$m,severidade:$s,labels:$labels,timestamp:$ts,hostname:$hn}'
            ;;
    esac
}

alerta_envia_curl() {
    local url="$1" payload="$2" canal="$3"
    local ct="application/json"
    [[ "$canal" == "telegram" ]] && ct="application/x-www-form-urlencoded"
    
    if (( ${DRY_RUN:-0} == 1 )); then
        log_debug "[DRY-RUN] curl -sf --max-time 10 -H 'Content-Type: $ct' -d '$payload' $url"
        echo "$payload" | jq . 2>/dev/null || echo "$payload"
        return 0
    fi
    
    local resp
    resp=$(curl -sf --max-time 10 -H "Content-Type: $ct" -d "$payload" "$url" 2>&1) || {
        log_erro "Falha ao enviar alerta para $canal: $resp"
        return 1
    }
    log_info "Alerta enviado para $canal"
}