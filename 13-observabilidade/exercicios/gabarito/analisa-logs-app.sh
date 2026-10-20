#!/usr/bin/env bash
#
# analisa-logs-app.sh - Análise de logs de aplicação (JSON Lines)
# Estende analisa-logs.sh com suporte a JSON estruturado.
#
# Uso:
#   analisa-logs-app.sh [-j|--json] [-v|--verbose] [-f|--formato TIPO]
#                      [-t|--tempo INI,FIM] [-l|--limite N]
#                      ARQUIVO_LOG [ARQUIVO_LOG...]
#
# Formatos:
#   json          JSON genérico (level, message)
#   json-app      Aplicação estruturada (timestamp, level, service, trace_id, duration_ms)
#   nginx, apache, syslog, generico (herdados)
#
# Opções:
#   -j, --json          Saída JSON
#   -v, --verbose       Inclui exemplos
#   -f, --formato TIPO  Formato (padrão: auto)
#   -t, --tempo INI,FIM Filtro temporal ISO8601
#   -l, --limite N      Top N (padrão: 10)
#   -h, --help          Exibe ajuda

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
VERBOSE=0
FORMATO="auto"
TEMPO_INICIO=""
TEMPO_FIM=""
LIMITE=10
ARQUIVOS=()

log() {
    local n="$1"
    shift
    local m
    m="$(date '+%F %T') [$n] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$m" >> "$LOG_FILE" 2>/dev/null || true
    case "$n" in
        ERRO|AVISO) printf '%s\n' "$m" >&2 ;;
        DEBUG) [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$m" ;;
        *) [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$m" ;;
    esac
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO  "$@"; }
log_debug() { log DEBUG "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }
usage() { sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; }

parse_tempo() {
    local a="$1"
    IFS=',' read -r TEMPO_INICIO TEMPO_FIM <<< "$a"
    [[ -n "$TEMPO_INICIO" ]] || die "tempo ini"
    date -d "$TEMPO_INICIO" +%s >/dev/null || die "tempo ini inválido"
    [[ -n "$TEMPO_FIM" ]] && date -d "$TEMPO_FIM" +%s >/dev/null || die "tempo fim inválido"
}

detecta_formato() {
    local a="$1" l
    l=$(head -1 "$a" 2>/dev/null || echo "")
    if [[ "$l" =~ ^\{.*\}$ ]]; then
        if echo "$l" | jq -e '.service and .trace_id and .duration_ms' >/dev/null 2>&1; then
            echo "json-app"
        else
            echo "json"
        fi
    elif [[ "$l" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*\"[A-Z]+\ .*\"[0-9]{3} ]]; then
        echo "nginx"
    elif [[ "$l" =~ ^[A-Z][a-z]{2}\ [0-9]{1,2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        echo "syslog"
    else
        echo "generico"
    fi
}

filtra_tempo_json() {
    local arq="$1"
    if [[ -z "$TEMPO_INICIO" ]]; then
        cat "$arq"
        return
    fi
    local ini fim
    ini=$(date -d "$TEMPO_INICIO" +%s)
    fim=9999999999
    [[ -n "$TEMPO_FIM" ]] && fim=$(date -d "$TEMPO_FIM" +%s)
    awk -v ini="$ini" -v fim="$fim" '
    {
        if (match($0, /"timestamp"[[:space:]]*:[[:space:]]*"([^"]+)"/, a)) {
            gsub(/[TZ]/," ",a[1])
            gsub(/\.[0-9]+/,"",a[1])
            cmd="date -d \"" a[1] "\" +%s"
            cmd | getline t
            close(cmd)
            if (t >= ini && t <= fim) print
        } else if (match($0, /"@timestamp"[[:space:]]*:[[:space:]]*"([^"]+)"/, a)) {
            gsub(/[TZ]/," ",a[1])
            gsub(/\.[0-9]+/,"",a[1])
            cmd="date -d \"" a[1] "\" +%s"
            cmd | getline t
            close(cmd)
            if (t >= ini && t <= fim) print
        }
    }' "$arq"
}

analisa_json_app() {
    local arq="$1"
    local dados
    dados=$(filtra_tempo_json "$arq")

    local total
    total=$(echo "$dados" | wc -l)
    [[ $total -eq 0 ]] && { echo '{}'; return; }

    # Contagem por level
    local levels
    levels=$(echo "$dados" | jq -r '.level // .severity // "unknown"' | sort | uniq -c | sort -rn | jq -R 'split(" ") | select(length==2) | {level: .[1], count: (.[0]|tonumber)}' | jq -s '.')

    # Top erros (warn, error, fatal)
    local top_erros
    top_erros=$(echo "$dados" | jq -r 'select(.level=="warn" or .level=="error" or .level=="fatal" or .severity=="warn" or .severity=="error" or .severity=="fatal") | .message // .msg // ""' | sort | uniq -c | sort -rn | head -"$LIMITE" | jq -R 'split(" ") | {msg: .[1:], count: (.[0]|tonumber)}' | jq -s '.')

    # Latência p50/p95/p99 por service
    local latencia
    latencia=$(echo "$dados" | jq -r 'select(.duration_ms != null) | "\(.service // "unknown") \(.duration_ms)"' | awk '{svc=$1; val=$2; a[svc][NR]=val} END {for (s in a) { n=asort(a[s]); p50=a[s][int(n*0.5)]; p95=a[s][int(n*0.95)]; p99=a[s][int(n*0.99)]; printf "{\"service\":\"%s\",\"p50\":%.1f,\"p95\":%.1f,\"p99\":%.1f,\"count\":%d},", s, p50, p95, p99, n }}' | sed 's/,$//')

    # Top trace_ids com erro
    local top_traces
    top_traces=$(echo "$dados" | jq -r 'select(.level=="error" or .level=="fatal" or .severity=="error" or .severity=="fatal") | .trace_id // ""' | grep -v '^$' | sort | uniq -c | sort -rn | head -"$LIMITE" | jq -R 'split(" ") | {trace_id: .[1], count: (.[0]|tonumber)}' | jq -s '.')

    # Error rate por minuto
    local error_rate
    error_rate=$(echo "$dados" | jq -r 'select(.level=="error" or .level=="fatal" or .severity=="error" or .severity=="fatal") | .timestamp // .["@timestamp"] // ""' | sed 's/T/ /; s/Z//; s/\.[0-9]*//' | awk '{print $1" "$2}' | sort | uniq -c | jq -R 'split(" ") | {minuto: .[1]" ".[2], errors: (.[0]|tonumber)}' | jq -s '.')

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n --arg arq "$arq" --argjson total "$total" --argjson levels "$levels" --argjson top_erros "$top_erros" --arg latencia "[$latencia]" --argjson top_traces "$top_traces" --argjson error_rate "$error_rate" --arg ts "$(date -Iseconds)" \
            '{arquivo: $arq, formato: "json-app", total_linhas: $total, levels: $levels, top_erros: $top_erros, latencia_por_service: ($latencia|fromjson), top_trace_ids: $top_traces, error_rate_por_minuto: $error_rate, timestamp: $ts}'
    else
        echo "=== $arq (json-app) ==="
        echo "Total: $total"
        echo "Levels: $(echo "$levels" | jq -c '.')"
        echo "Top erros: $(echo "$top_erros" | jq -c '.')"
        echo "Latência: $latencia"
        echo "Top traces: $(echo "$top_traces" | jq -c '.')"
        echo "Error rate: $(echo "$error_rate" | jq -c '.')"
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -f|--formato) FORMATO="${2:-}"; shift 2 ;;
            -t|--tempo) parse_tempo "$2"; shift 2 ;;
            -l|--limite) LIMITE="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) ARQUIVOS+=("$1"); shift ;;
        esac
    done

    [[ ${#ARQUIVOS[@]} -gt 0 ]] || { usage >&2; die "arquivo obrigatório" 2; }
    [[ "$LIMITE" =~ ^[0-9]+$ ]] && (( LIMITE > 0 )) || die "limite: $LIMITE" 2

    requer_comando jq
    requer_comando awk

    local all="[]"
    for arq in "${ARQUIVOS[@]}"; do
        [[ -f "$arq" ]] || { log_aviso "não encontrado: $arq"; continue; }
        local fmt="$FORMATO"
        [[ "$fmt" == "auto" ]] && fmt=$(detecta_formato "$arq")

        local result
        case "$fmt" in
            json-app) result=$(analisa_json_app "$arq") ;;
            json) result=$(echo "$all") ;;
            *) result=$(echo "$all") ;;
        esac

        all=$(echo "$all" | jq -c --argjson r "$result" '. + [$r]')
    done

    [[ "$JSON_OUTPUT" -eq 1 ]] && jq -n --argjson results "$all" --arg ts "$(date -Iseconds)" '{timestamp: $ts, analises: $results}'
}

main "$@"