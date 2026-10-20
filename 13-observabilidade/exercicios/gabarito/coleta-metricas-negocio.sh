#!/usr/bin/env bash
#
# coleta-metricas-negocio.sh - Coleta métricas de negócio de múltiplas fontes
# Exporta no formato Prometheus textfile collector.
#
# Uso:
#   coleta-metricas-negocio.sh [-s|--source TIPO] [-f|--file ARQ]
#                             [-q|--query SQL] [-d|--dsn DSN]
#                             [-u|--url URL] [-H|--header "K: V"]
#                             [-o|--output DIR] [-p|--prefixo NOME]
#                             [--dry-run] [-h|--help]
#
# Fontes:
#   file    Lê JSON de arquivo (metric_name, value, labels)
#   db      Executa query SQL (PostgreSQL/MySQL)
#   api     Chama HTTP endpoint JSON
#
# Opções:
#   -s, --source TIPO    Fonte: file, db, api (padrão: file)
#   -f, --file ARQ       Arquivo JSON (source=file)
#   -q, --query SQL      Query SQL (source=db)
#   -d, --dsn DSN        Connection string (source=db)
#   -u, --url URL        Endpoint API (source=api)
#   -H, --header "K:V"   Header HTTP (source=api, repetível)
#   -o, --output DIR     Diretório saída (padrão: /var/lib/node_exporter/textfile_collector)
#   -p, --prefixo NOME   Prefixo métricas (padrão: app)
#   --dry-run            Mostra métricas no stdout
#   -h, --help           Exibe ajuda
#
# Formato arquivo JSON (source=file):
#   {"metric_name": "pedidos_pendentes", "value": 42, "labels": {"status": "pendente", "loja": "sp"}}
#   {"metric_name": "receita_total", "value": 12345.67, "labels": {"moeda": "BRL"}}
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

SOURCE="file"
FILE_INPUT=""
QUERY=""
DSN=""
API_URL=""
HEADERS=()
OUTPUT_DIR="/var/lib/node_exporter/textfile_collector"
PREFIXO="app"
DRY_RUN=0

log() {
    local n="$1"
    shift
    local m
    m="$(date '+%F %T') [$n] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$m" >> "$LOG_FILE" 2>/dev/null || true
    case "$n" in
        ERRO|AVISO) printf '%s\n' "$m" >&2 ;;
        DEBUG) [[ "$DRY_RUN" -eq 1 ]] && printf '%s\n' "$m" ;;
        *) printf '%s\n' "$m" ;;
    esac
}
log_info() { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro() { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }
die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }
usage() { sed -n '3,32p' "$0" | sed 's/^# \{0,1\}//'; }

valida_metric_name() { [[ "$1" =~ ^[a-z_:][a-z0-9_:]*$ ]] || return 1; }

escreve_metrica() {
    local nome
    nome="$1" valor="$2" labels="$3" tipo="${4:-gauge}" ajuda="${5:-Métrica de negócio}"
    printf '# HELP %s %s\n# TYPE %s %s\n%s{%s} %s\n\n' "$nome" "$ajuda" "$nome" "$tipo" "$nome" "$labels" "$valor"
}

# --- Source: file ---
coleta_file() {
    local arq="$1"
    [[ -f "$arq" ]] || die "arquivo não encontrado: $arq" 1
    [[ -r "$arq" ]] || die "sem permissão: $arq" 1
    
    local total=0
    while IFS= read -r linha; do
        [[ -z "$linha" ]] && continue
        local nome valor labels_json
        nome=$(echo "$linha" | jq -r '.metric_name // empty')
        valor=$(echo "$linha" | jq -r '.value // empty')
        labels_json=$(echo "$linha" | jq -c '.labels // {}')
        
        [[ -z "$nome" || -z "$valor" ]] && { log_aviso "linha inválida (metric_name/value obrigatórios): $linha"; continue; }
        valida_metric_name "$nome" || { log_aviso "nome métrica inválido: $nome"; continue; }
        
        local labels=""
        if [[ "$labels_json" != "{}" ]]; then
            labels=$(echo "$labels_json" | jq -r 'to_entries | map("\(.key)=\"\(.value)\"") | join(",")')
        fi
        
        # Adiciona labels padrão
        local labels_final
        labels_final="app=\"${PREFIXO}\",environment=\"prod\""
        [[ -n "$labels" ]] && labels_final="${labels_final},${labels}"
        
        escreve_metrica "${PREFIXO}_${nome}" "$valor" "$labels_final"
        ((total++))
    done < "$arq"
    
    log_info "coletadas $total métricas de $arq"
}

# --- Source: db ---
coleta_db() {
    local dsn="$1" query="$2"
    local cmd
    
    if [[ "$dsn" =~ ^postgresql:// ]] || [[ "$dsn" =~ ^postgres:// ]] || command -v psql >/dev/null 2>&1; then
        requer_comando psql
        cmd="psql \"$dsn\" -t -A -F $'\t' -c \"$query\""
    elif [[ "$dsn" =~ ^mysql:// ]] || command -v mysql >/dev/null 2>&1; then
        requer_comando mysql
        cmd="mysql -N -B -e \"$query\" \"$dsn\""
    else
        die "psql ou mysql não encontrado" 3
    fi
    
    log_debug "executando: $cmd"
    
    local total=0
    eval "$cmd" 2>/dev/null | while IFS=$'\t' read -r nome valor labels_str; do
        [[ -z "$nome" ]] && continue
        valida_metric_name "$nome" || { log_aviso "nome inválido: $nome"; continue; }
        
        local labels
        labels="app=\"${PREFIXO}\",environment=\"prod\""
        if [[ -n "$labels_str" ]]; then
            labels="${labels},${labels_str}"
        fi
        
        escreve_metrica "${PREFIXO}_${nome}" "$valor" "$labels"
        ((total++))
    done
    
    log_info "coletadas métricas do banco"
}

# --- Source: api ---
coleta_api() {
    local url="$1"
    requer_comando curl
    requer_comando jq
    
    local curl_opts=(-sf --max-time 30)
    for h in "${HEADERS[@]}"; do
        curl_opts+=(-H "$h")
    done
    
    local resposta
    resposta=$(curl "${curl_opts[@]}" "$url" 2>/dev/null) || die "falha ao chamar API: $url" 1
    
    # Espera array de objetos: [{"metric_name": "...", "value": ..., "labels": {...}}]
    local total=0
    echo "$resposta" | jq -c '.[]?' | while IFS= read -r item; do
        local nome valor labels_json
        nome=$(echo "$item" | jq -r '.metric_name // empty')
        valor=$(echo "$item" | jq -r '.value // empty')
        labels_json=$(echo "$item" | jq -c '.labels // {}')
        
        [[ -z "$nome" || -z "$valor" ]] && continue
        valida_metric_name "$nome" || continue
        
        local labels
        labels="app=\"${PREFIXO}\",environment=\"prod\""
        if [[ "$labels_json" != "{}" ]]; then
            local l
            l=$(echo "$labels_json" | jq -r 'to_entries | map("\(.key)=\"\(.value)\"") | join(",")')
            labels="${labels},${l}"
        fi
        
        escreve_metrica "${PREFIXO}_${nome}" "$valor" "$labels"
        ((total++))
    done
    
    log_info "coletadas métricas da API"
}

# --- Main ---
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--source) SOURCE="${2:-}"; shift 2 ;;
            -f|--file) FILE_INPUT="${2:-}"; shift 2 ;;
            -q|--query) QUERY="${2:-}"; shift 2 ;;
            -d|--dsn) DSN="${2:-}"; shift 2 ;;
            -u|--url) API_URL="${2:-}"; shift 2 ;;
            -H|--header) HEADERS+=("$2"); shift 2 ;;
            -o|--output) OUTPUT_DIR="${2:-}"; shift 2 ;;
            -p|--prefixo) PREFIXO="${2:-}"; shift 2 ;;
            --dry-run) DRY_RUN=1; shift ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento: $1" 2 ;;
        esac
    done

    [[ "$SOURCE" =~ ^(file|db|api)$ ]] || die "source inválido: $SOURCE (file|db|api)" 2
    valida_metric_name "$PREFIXO" || die "prefixo inválido: $PREFIXO" 2
    [[ "$DRY_RUN" -eq 1 ]] || { mkdir -p "$OUTPUT_DIR" 2>/dev/null || die "não pode criar $OUTPUT_DIR"; [[ -w "$OUTPUT_DIR" ]] || die "sem permissão em $OUTPUT_DIR"; }

    local output_file
    output_file="${OUTPUT_DIR}/${PREFIXO}_negocio.prom"
    local temp_file
    temp_file="${output_file}.tmp.$$"

    log_info "início (source=$SOURCE, prefixo=$PREFIXO, dry-run=$DRY_RUN)"

    {
        echo "# Coletado em $(date -Iseconds) por $SCRIPT_NAME (source=$SOURCE)"
        echo "# Host: $(hostname)"
        echo
        
        case "$SOURCE" in
            file) [[ -n "$FILE_INPUT" ]] || die "arquivo obrigatório para source=file" 2; coleta_file "$FILE_INPUT" ;;
            db) [[ -n "$QUERY" && -n "$DSN" ]] || die "query e dsn obrigatórios para source=db" 2; coleta_db "$DSN" "$QUERY" ;;
            api) [[ -n "$API_URL" ]] || die "url obrigatória para source=api" 2; coleta_api "$API_URL" ;;
        esac
    } > "$temp_file"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        cat "$temp_file"
        rm -f "$temp_file"
    else
        mv "$temp_file" "$output_file"
        log_info "métricas escritas em $output_file"
    fi
}

main "$@"