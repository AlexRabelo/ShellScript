#!/usr/bin/env bash
#
# monitoramento-completo.sh - Pipeline completo de monitoramento SRE
#
# Uso: monitoramento-completo.sh [-j|--json] [-n|--dry-run] [-v|--verbose] [-c|--config ARQ] [-h|--help]
#
# Orquestra: healthcheck -> incidente se falha -> analisa logs -> verifica disco -> alerta -> relatório JSON
#
# Opções:
#   -j, --json       Saída JSON
#   -n, --dry-run    Simula execução sem alterar nada
#   -v, --verbose    Modo verboso (DEBUG)
#   -c, --config ARQ Arquivo de configuração (padrão: ~/.config/sre-toolkit.conf)
#   -h, --help       Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso (tudo OK) | 1 problemas detectados | 2 uso incorreto | 3 pré-requisito ausente

set -Eeuo pipefail

# --- Configuração ---
readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
DRY_RUN=0
VERBOSE=0
CONFIG_FILE=""
SERVICOS_FILE="servicos.txt"
ENDPOINTS_FILE="endpoints.txt"
LOG_FILES=()
DISCO_DIR="/tmp"
DISCO_DIAS=30
ALERT_WEBHOOK=""

# --- Log ---
log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      (( VERBOSE == 1 )) && printf '%s\n' "$msg" ;;
        *)          (( JSON_OUTPUT == 0 )) && printf '%s\n' "$msg" ;;
    esac
}
log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; (( c != 0 )) && log_erro "terminou com falha (código $c)" || log_info "terminou com sucesso"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM
trap 'log_erro "erro linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades ---
run() {
    if (( DRY_RUN == 1 )); then
        log_info "[DRY-RUN] $*"
    else
        log_debug "executando: $*"
        "$@"
    fi
}

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando obrigatório: $1" 3; }

usage() { sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'; }

carrega_config() {
    [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]] || return 0
    log_info "Carregando configuração: $CONFIG_FILE"
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    ALERT_WEBHOOK="${ALERT_WEBHOOK_URL:-}"
}

# --- Funções do Pipeline ---

# 1. Healthcheck
executa_healthcheck() {
    log_info "=== 1/6: Healthcheck dos serviços ==="

    local json
    json=$(run sre-toolkit health -j -s "$SERVICOS_FILE" -e "$ENDPOINTS_FILE" 2>/dev/null) || {
        log_erro "Falha ao executar healthcheck"
        echo '{"erro": "healthcheck falhou"}'
        return 1
    }

    local fail
    fail=$(echo "$json" | jq -r '.fail // 0')
    echo "$json"
    return $(( fail > 0 ? 1 : 0 ))
}

# 2. Coleta incidente se houver falhas
executa_incidente() {
    local health_json="$1"
    local fail
    fail=$(echo "$health_json" | jq -r '.fail // 0')

    (( fail == 0 )) && { log_info "Nenhuma falha no healthcheck, pulando coleta de incidente"; echo "{}"; return 0; }

    log_info "=== 2/6: Coletando diagnóstico de incidente ==="

    local dir
    dir="/tmp/incidente-$(date +%F-%H%M%S)"
    local json
    json=$(run sre-toolkit incidente --coleta-completa --dir "$dir" -j 2>/dev/null) || {
        log_erro "Falha ao coletar incidente"
        echo '{"erro": "incidente falhou"}'
        return 1
    }

    # Compacta
    run tar -czf "${dir}.tar.gz" -C /tmp "$(basename "$dir")" 2>/dev/null || true
    log_info "Incidente compactado: ${dir}.tar.gz"

    echo "$json" | jq -c --arg arquivo "${dir}.tar.gz" '. + {arquivo_compactado: $arquivo}'
}

# 3. Analisa logs de erro
analisa_logs() {
    log_info "=== 3/6: Analisando logs ==="

    local all_results="[]"

    for arq in "${LOG_FILES[@]}"; do
        [[ -f "$arq" ]] || { log_aviso "Log não encontrado: $arq"; continue; }

        local json
        json=$(run sre-toolkit logs -f json -j "$arq" 2>/dev/null) || {
            log_aviso "Falha ao analisar $arq"
            continue
        }

        all_results=$(echo "$all_results" | jq -c --argjson a "$json" '. + $a.analises')
    done

    jq -n --argjson logs "$all_results" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{timestamp: $ts, logs_analisados: $logs}'
}

# 4. Verifica disco
verifica_disco() {
    log_info "=== 4/6: Verificando disco ==="

    local json
    json=$(run sre-toolkit disco --dir "$DISCO_DIR" --dias "$DISCO_DIAS" -j 2>/dev/null) || {
        log_erro "Falha ao verificar disco"
        echo '{"erro": "disco falhou"}'
        return 1
    }

    echo "$json"
}

# 5. Envia alerta se houver problemas
envia_alerta() {
    local health_json="$1" disco_json="$2" incidente_json="$3"

    local health_fail disco_antigos
    health_fail=$(echo "$health_json" | jq -r '.fail // 0')
    disco_antigos=$(echo "$disco_json" | jq -r '.arquivos_mais_antigos // 0')

    local tem_problema=0
    (( health_fail > 0 )) && tem_problema=1
    (( disco_antigos > 100 )) && tem_problema=1  # threshold arbitrário

    (( tem_problema == 0 )) && { log_info "Nenhum problema crítico, sem alerta"; echo "{}"; return 0; }

    [[ -z "$ALERT_WEBHOOK" ]] && { log_aviso "Webhook não configurado, pulando alerta"; echo "{}"; return 0; }

    log_info "=== 5/6: Enviando alerta ==="

    local titulo="🚨 Alerta SRE - Problemas Detectados"
    local msg="Healthcheck falhas: $health_fail | Arquivos antigos em disco: $disco_antigos"
    local severidade="warning"
    (( health_fail > 0 )) && severidade="critical"

    local payload
    payload=$(jq -n --arg t "$titulo" --arg m "$msg" --arg s "$severidade" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg hn "$(hostname)" \
        '{titulo:$t,mensagem:$m,severidade:$s,timestamp:$ts,hostname:$hn}')

    if (( DRY_RUN == 1 )); then
        log_info "[DRY-RUN] curl -sf --max-time 10 -H 'Content-Type: application/json' -d '$payload' $ALERT_WEBHOOK"
        echo '{"status": "dry-run", "payload": '"$payload"'}'
    else
        local resp
        resp=$(curl -sf --max-time 10 -H "Content-Type: application/json" -d "$payload" "$ALERT_WEBHOOK" 2>&1) || {
            log_erro "Falha ao enviar alerta: $resp"
            echo '{"erro": "alerta falhou"}'
            return 1
        }
        log_info "Alerta enviado com sucesso"
        echo '{"status": "enviado"}'
    fi
}

# 6. Gera relatório consolidado
gera_relatorio() {
    local health_json="$1" incidente_json="$2" logs_json="$3" disco_json="$4" alerta_json="$5"

    log_info "=== 6/6: Gerando relatório consolidado ==="

    local status_geral="ok"
    local health_fail
    health_fail=$(echo "$health_json" | jq -r '.fail // 0')
    (( health_fail > 0 )) && status_geral="falha"

    jq -n \
        --argjson health "$health_json" \
        --argjson incidente "$incidente_json" \
        --argjson logs "$logs_json" \
        --argjson disco "$disco_json" \
        --argjson alerta "$alerta_json" \
        --arg status "$status_geral" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{timestamp: $ts, status_geral: $status, healthcheck: $health, incidente: $incidente, logs: $logs, disco: $disco, alerta: $alerta}'
}

# --- Main ---
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -c|--config) CONFIG_FILE="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) die "Opção desconhecida: $1" 2 ;;
        esac
    done

    carrega_config
    requer_comando sre-toolkit
    requer_comando jq
    requer_comando curl
    requer_comando tar

    [[ -f "$SERVICOS_FILE" ]] || die "Arquivo de serviços não encontrado: $SERVICOS_FILE" 2
    [[ -f "$ENDPOINTS_FILE" ]] || die "Arquivo de endpoints não encontrado: $ENDPOINTS_FILE" 2

    log_info "início (json=$JSON_OUTPUT, dry-run=$DRY_RUN, verbose=$VERBOSE)"

    # Pipeline
    local health_json incidente_json logs_json disco_json alerta_json relatorio

    health_json=$(executa_healthcheck) || true
    incidente_json=$(executa_incidente "$health_json") || incidente_json='{}'
    logs_json=$(analisa_logs) || logs_json='{}'
    disco_json=$(verifica_disco) || disco_json='{}'
    alerta_json=$(envia_alerta "$health_json" "$disco_json" "$incidente_json") || alerta_json='{}'
    relatorio=$(gera_relatorio "$health_json" "$incidente_json" "$logs_json" "$disco_json" "$alerta_json")

    if (( JSON_OUTPUT == 1 )); then
        echo "$relatorio"
    else
        echo "$relatorio" | jq .
    fi

    local status
    status=$(echo "$relatorio" | jq -r '.status_geral')
    log_info "fim (status=$status)"
    [[ "$status" == "ok" ]] || exit 1
}

main "$@"