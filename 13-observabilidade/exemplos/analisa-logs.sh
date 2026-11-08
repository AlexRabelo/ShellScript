#!/usr/bin/env bash
#
# analisa-logs.sh - Análise de logs estruturados (nginx, apache, app, syslog)
# Extrai métricas: top IPs, erros por hora, latência, status codes, anomalias.
# Saída texto ou JSON para ingestão em SIEM/Grafana.
#
# Uso:
#   analisa-logs.sh [-j|--json] [-v|--verbose] [-f|--formato TIPO]
#                  [-t|--tempo INICIO[,FIM]] [-l|--limite N]
#                  ARQUIVO_LOG [ARQUIVO_LOG...]
#
# Opções:
#   -j, --json          Saída JSON
#   -v, --verbose       Inclui exemplos de linhas
#   -f, --formato TIPO  Formato do log: nginx, apache, json, syslog, generico (padrão: auto)
#   -t, --tempo INI,FIM Filtro temporal: "2026-10-13 10:00,2026-10-13 11:00"
#   -l, --limite N      Top N resultados (padrão: 10)
#   -h, --help          Exibe ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto
#
# Exemplos:
#   analisa-logs.sh /var/log/nginx/access.log
#   analisa-logs.sh -j -f nginx -l 20 /var/log/nginx/access.log
#   analisa-logs.sh -t "2026-10-13 10:00,2026-10-13 11:00" /var/log/app.log
#   analisa-logs.sh -j -f json /var/log/app.json.log | jq '.top_ips'

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
VERBOSE=0
FORMATO="auto"
TEMPO_INICIO=""
TEMPO_FIM=""
LIMITE=10
ARQUIVOS=()

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG) if (( VERBOSE == 1 )); then printf '%s\n' "$msg"; fi ;;
        *) if (( JSON_OUTPUT == 0 )); then printf '%s\n' "$msg"; fi ;;
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

# --- Parse temporal ---
parse_tempo() {
    local arg="$1"
    IFS=',' read -r TEMPO_INICIO TEMPO_FIM <<< "$arg"
    [[ -n "$TEMPO_INICIO" ]] || die "tempo inicial obrigatório" 2
    date -d "$TEMPO_INICIO" +%s >/dev/null 2>&1 || die "formato tempo inicial inválido: $TEMPO_INICIO" 2
if [[ -n "$TEMPO_FIM" ]]; then
        date -d "$TEMPO_FIM" +%s >/dev/null 2>&1 || die "formato tempo final inválido: $TEMPO_FIM" 2
    fi
}

# --- Detecta formato do log ---
detecta_formato() {
    local arquivo="$1"
    local primeira
    primeira=$(head -1 "$arquivo" 2>/dev/null || echo "")
    
    if [[ "$primeira" =~ ^\{.*\}$ ]]; then
        echo "json"
    elif [[ "$primeira" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*\"[A-Z]+\ .*\"[0-9]{3} ]]; then
        echo "nginx"
    elif [[ "$primeira" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*\[.*\].*\"[A-Z]+\ .*\"[0-9]{3} ]]; then
        echo "apache"
    elif [[ "$primeira" =~ ^[A-Z][a-z]{2}\ [0-9]{1,2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        echo "syslog"
    else
        echo "generico"
    fi
}

# --- Extrai timestamp da linha (nginx/apache/syslog) ---
extrai_timestamp() {
    local formato="$1" linha="$2"
    case "$formato" in
        nginx|apache)
            echo "$linha" | sed -n 's/.*\[\([^]]*\)\].*/\1/p' | sed 's|/|-|g; s/:/ /' | awk '{print $1"-"$2"-"$3" "$4":"$5":"$6}'
            ;;
        syslog)
            echo "$linha" | awk '{print $1" "$2" "$3}' | sed "s/^/$(date +%Y)-/"
            ;;
        *)
            echo ""
            ;;
    esac
}

# --- Filtra por tempo ---
filtra_tempo() {
    local arquivo="$1" formato="$2"
    if [[ -z "$TEMPO_INICIO" ]]; then
        cat "$arquivo"
        return
    fi
    
    local ini_fim
    ini_fim=$(date -d "$TEMPO_INICIO" +%s)
    local fim_fim=9999999999
    [[ -n "$TEMPO_FIM" ]] && fim_fim=$(date -d "$TEMPO_FIM" +%s)
    
    awk -v ini="$ini_fim" -v fim="$fim_fim" -v fmt="$formato" '
    function parse_ts(line,    ts, parts, mon, day, time, year, month_num) {
        if (fmt == "nginx" || fmt == "apache") {
            match(line, /\[([^]]+)\]/, parts)
            ts = parts[1]
            gsub("/", "-", ts)
            split(ts, a, /[-:]/)
            month_num = (a[2] ~ /Jan/)?1:(a[2]~/Feb/)?2:(a[2]~/Mar/)?3:(a[2]~/Apr/)?4:(a[2]~/May/)?5:(a[2]~/Jun/)?6:(a[2]~/Jul/)?7:(a[2]~/Aug/)?8:(a[2]~/Sep/)?9:(a[2]~/Oct/)?10:(a[2]~/Nov/)?11:12
            return mktime(a[3]" "month_num" "a[1]" "a[4]" "a[5]" "a[6])
        } else if (fmt == "syslog") {
            split(line, a, " ")
            month_num = (a[1] ~ /Jan/)?1:(a[1]~/Feb/)?2:(a[1]~/Mar/)?3:(a[1]~/Apr/)?4:(a[1]~/May/)?5:(a[1]~/Jun/)?6:(a[1]~/Jul/)?7:(a[1]~/Aug/)?8:(a[1]~/Sep/)?9:(a[1]~/Oct/)?10:(a[1]~/Nov/)?11:12
            return mktime(strftime("%Y")" "month_num" "a[2]" "a[3])
        }
        return 0
    }
    { ts = parse_ts($0); if (ts >= ini && ts <= fim) print }
    ' "$arquivo"
}

# --- Análise nginx/apache ---
analisa_acesso() {
    local arquivo="$1" formato="$2"
    local dados
    dados=$(filtra_tempo "$arquivo" "$formato")
    
    local total_linhas
    total_linhas=$(echo "$dados" | wc -l)
    
    # Top IPs
    local top_ips
    top_ips=$(echo "$dados" | awk '{print $1}' | sort | uniq -c | sort -rn | head -"$LIMITE" | awk '{printf "{\"ip\":\"%s\",\"count\":%d},", $2, $1}' | sed 's/,$//')
    
    # Status codes
    local status_codes
    status_codes=$(echo "$dados" | awk '{print $9}' | sort | uniq -c | sort -rn | awk '{printf "{\"code\":\"%s\",\"count\":%d},", $2, $1}' | sed 's/,$//')
    
    # Top endpoints
    local top_endpoints
    top_endpoints=$(echo "$dados" | awk -F'"' '{print $2}' | awk '{print $2}' | sort | uniq -c | sort -rn | head -"$LIMITE" | awk '{printf "{\"endpoint\":\"%s\",\"count\":%d},", substr($0, index($0,$2)), $1}' | sed 's/,$//')
    
    # Erros 4xx/5xx por hora
    local erros_hora
    erros_hora=$(echo "$dados" | awk '$9 ~ /^[45]/ {match($0, /\[([^]]+)\]/, a); gsub(/[:-]/, " ", a[1]); split(a[1], b, "/"); m=(b[2]~/Jan/)?1:(b[2]~/Feb/)?2:(b[2]~/Mar/)?3:(b[2]~/Apr/)?4:(b[2]~/May/)?5:(b[2]~/Jun/)?6:(b[2]~/Jul/)?7:(b[2]~/Aug/)?8:(b[2]~/Sep/)?9:(b[2]~/Oct/)?10:(b[2]~/Nov/)?11:12; printf "%04d-%02d-%02d %02d:00\n", b[3], m, b[1], b[4]}' | sort | uniq -c | sort -rn | awk '{printf "{\"hora\":\"%s %s\",\"count\":%d},", $2, $3, $1}' | sed 's/,$//')
    
    # Latência (nginx com $request_time no final)
    local latencia_stats=""
    if [[ "$formato" == "nginx" ]]; then
        latencia_stats=$(echo "$dados" | awk '{print $NF}' | awk 'BEGIN{c=0;s=0;min=9999;max=0} /^[0-9.]+$/{c++; s+=$1; if($1<min) min=$1; if($1>max) max=$1} END{if(c>0) printf "{\"count\":%d,\"avg\":%.3f,\"min\":%.3f,\"max\":%.3f}", c, s/c, min, max}')
    fi
    
    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n \
            --arg arquivo "$arquivo" \
            --arg formato "$formato" \
            --argjson total "$total_linhas" \
            --argjson limite "$LIMITE" \
            --arg top_ips "[$top_ips]" \
            --arg status_codes "[$status_codes]" \
            --arg top_endpoints "[$top_endpoints]" \
            --arg erros_hora "[$erros_hora]" \
            --arg latencia_stats "$latencia_stats" \
            --arg timestamp "$(date -Iseconds)" \
            '{arquivo: $arquivo, formato: $formato, total_linhas: $total, limite: $limite, top_ips: ($top_ips|fromjson), status_codes: ($status_codes|fromjson), top_endpoints: ($top_endpoints|fromjson), erros_por_hora: ($erros_hora|fromjson), latencia: ($latencia_stats|fromjson), timestamp: $timestamp}'
    else
        echo "=== $arquivo ($formato) ==="
        echo "Total linhas: $total_linhas"
        echo
        echo "Top $LIMITE IPs:"
        echo "$dados" | awk '{print $1}' | sort | uniq -c | sort -rn | head -"$LIMITE" | awk '{printf "  %8d %s\n", $1, $2}'
        echo
        echo "Status codes:"
        echo "$dados" | awk '{print $9}' | sort | uniq -c | sort -rn | awk '{printf "  %8d %s\n", $1, $2}'
        echo
        echo "Top $LIMITE endpoints:"
        echo "$dados" | awk -F'"' '{print $2}' | awk '{print $2}' | sort | uniq -c | sort -rn | head -"$LIMITE" | awk '{printf "  %8d %s\n", $1, substr($0, index($0,$2))}'
        [[ -n "$latencia_stats" ]] && echo "Latência: $latencia_stats"
        echo
    fi
}

# --- Análise JSON ---
analisa_json() {
    local arquivo="$1"
    local dados
    dados=$(filtra_tempo "$arquivo" "json")
    
    local total_linhas
    total_linhas=$(echo "$dados" | wc -l)
    
    # Assume JSON lines com campos: level, message, timestamp, service, etc.
    local levels
    levels=$(echo "$dados" | jq -r '.level // .severity // "unknown"' 2>/dev/null | sort | uniq -c | sort -rn | awk '{printf "{\"level\":\"%s\",\"count\":%d},", $2, $1}' | sed 's/,$//')
    
    local top_messages
    top_messages=$(echo "$dados" | jq -r '.message // .msg // ""' 2>/dev/null | sort | uniq -c | sort -rn | head -"$LIMITE" | awk '{printf "{\"msg\":\"%s\",\"count\":%d},", substr($0, index($0,$2)), $1}' | sed 's/,$//')
    
    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n --arg arquivo "$arquivo" --argjson total "$total_linhas" --arg levels "[$levels]" --arg top_messages "[$top_messages]" --arg ts "$(date -Iseconds)" \
            '{arquivo: $arquivo, formato: "json", total_linhas: $total, levels: ($levels|fromjson), top_messages: ($top_messages|fromjson), timestamp: $ts}'
    else
        echo "=== $arquivo (json) ==="
        echo "Total: $total_linhas"
        echo "Levels: $levels"
        echo "Top mensagens: $top_messages"
    fi
}

# --- Análise genérica ---
analisa_generico() {
    local arquivo="$1"
    local total_linhas
    total_linhas=$(wc -l < "$arquivo")
    
    local top_palavras
    top_palavras=$(grep -oE '\b\w{4,}\b' "$arquivo" | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -rn | head -"$LIMITE" | awk '{printf "{\"word\":\"%s\",\"count\":%d},", $2, $1}' | sed 's/,$//')
    
    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n --arg arquivo "$arquivo" --argjson total "$total_linhas" --arg top_palavras "[$top_palavras]" --arg ts "$(date -Iseconds)" \
            '{arquivo: $arquivo, formato: "generico", total_linhas: $total, top_palavras: ($top_palavras|fromjson), timestamp: $ts}'
    else
        echo "=== $arquivo (generico) ==="
        echo "Total linhas: $total_linhas"
        echo "Top palavras: $top_palavras"
    fi
}

# --- Main --------------------------------------------------------------------
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

if [[ "$LIMITE" =~ ^[0-9]+$ ]] && (( LIMITE > 0 )); then
        :
    else
        die "limite inválido: $LIMITE" 2
    fi

    requer_comando awk
    [[ "$JSON_OUTPUT" -eq 1 ]] && requer_comando jq

    local all_results="[]"
    
    for arq in "${ARQUIVOS[@]}"; do
        [[ -f "$arq" ]] || { log_aviso "arquivo não encontrado: $arq"; continue; }
        [[ -r "$arq" ]] || { log_aviso "sem permissão: $arq"; continue; }
        
        local fmt="$FORMATO"
        [[ "$fmt" == "auto" ]] && fmt=$(detecta_formato "$arq")
        
        log_info "analisando: $arq (formato: $fmt)"
        
        local result
        case "$fmt" in
            nginx|apache) result=$(analisa_acesso "$arq" "$fmt") ;;
            json) result=$(analisa_json "$arq") ;;
            *) result=$(analisa_generico "$arq") ;;
        esac
        
        all_results=$(echo "$all_results" | jq -c --argjson r "$result" '. + [$r]')
    done

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n --argjson results "$all_results" --arg ts "$(date -Iseconds)" '{timestamp: $ts, analises: $results}'
    fi
}

main "$@"