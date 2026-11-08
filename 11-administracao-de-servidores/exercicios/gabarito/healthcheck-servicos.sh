#!/usr/bin/env bash
#
# healthcheck-servicos.sh - Healthcheck de serviços systemd e endpoints HTTP
# Verifica status de serviços e endpoints, gera relatório texto ou JSON.
#
# Uso:
#   healthcheck-servicos.sh [-j|--json] [-v|--verbose] [-t|--timeout S]
#                          [-s|--servicos ARQ] [-e|--endpoints ARQ] [-h|--help]
#
# Opções:
#   -j, --json           Saída em JSON (padrão: texto)
#   -v, --verbose        Inclui detalhes de cada verificação
#   -t, --timeout S      Timeout para HTTP em segundos (padrão: 5)
#   -s, --servicos ARQ   Arquivo com lista de serviços systemd (padrão: servicos.txt)
#   -e, --endpoints ARQ  Arquivo com lista de endpoints HTTP (padrão: endpoints.txt)
#   -h, --help           Exibe esta ajuda
#
# Códigos de saída:
#   0 todos OK | 1 alguma falha | 2 uso incorreto | 3 pré-requisito ausente
#
# Exemplos:
#   healthcheck-servicos.sh                              # Texto, arquivos padrão
#   healthcheck-servicos.sh -j -v                        # JSON verboso
#   healthcheck-servicos.sh -s meus-servicos.txt -t 10   # Timeout 10s

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
VERBOSE=0
TIMEOUT=5
ARQ_SERVICOS="servicos.txt"
ARQ_ENDPOINTS="endpoints.txt"

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      if [[ "$VERBOSE" -eq 1 ]]; then printf '%s\n' "$msg"; fi ;;
        *)          [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() {
    local codigo="${2:-1}"
    log_erro "$1"
    exit "$codigo"
}

# --- Limpeza -----------------------------------------------------------------
cleanup() {
    local codigo=$?
    [[ $codigo -eq 0 ]] || log_erro "terminou com falha (código ${codigo})"
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades --------------------------------------------------------------
requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

ler_lista() {
    local arquivo="$1"
    [[ -f "$arquivo" ]] || die "arquivo não encontrado: $arquivo" 1
    grep -v '^\s*#' "$arquivo" | grep -v '^\s*$' | sed 's/#.*$//' | sed 's/^\s*//;s/\s*$//'
}

# --- Verificações ------------------------------------------------------------
verificar_systemd() {
    local servico="$1"
    local timestamp
    timestamp=$(date -Iseconds)

    if systemctl is-active --quiet "$servico" 2>/dev/null; then
        echo "ok"
        [[ "$VERBOSE" -eq 1 ]] && log_debug "systemd: $servico = ativo"
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            jq -n --arg tipo "systemd" --arg nome "$servico" --arg status "ok" --arg detalhes "serviço ativo" --arg ts "$timestamp" '{tipo: $tipo, nome: $nome, status: $status, detalhes: $detalhes, timestamp: $ts}'
        else
            printf '  \033[0;32m[OK]\033[0m  %s (systemd)\n' "$servico"
        fi
        return 0
    else
        local estado
        estado=$(systemctl is-active "$servico" 2>/dev/null || echo "desconhecido")
        [[ "$VERBOSE" -eq 1 ]] && log_aviso "systemd: $servico = $estado"
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            jq -n --arg tipo "systemd" --arg nome "$servico" --arg status "fail" --arg detalhes "estado: $estado" --arg ts "$timestamp" '{tipo: $tipo, nome: $nome, status: $status, detalhes: $detalhes, timestamp: $ts}'
        else
            printf '  \033[0;31m[FALHA]\033[0m %s (systemd) - %s\n' "$servico" "$estado"
        fi
        return 1
    fi
}

verificar_http() {
    local url="$1"
    local timestamp
    timestamp=$(date -Iseconds)

    local saida codigo http_code
    saida=$(curl -sf --max-time "$TIMEOUT" -w "\n%{http_code}" "$url" 2>/dev/null || true)
    codigo=$?
    http_code=$(echo "$saida" | tail -1)
    local corpo
    corpo=$(echo "$saida" | head -n -1)

    if [[ $codigo -eq 0 && "$http_code" =~ ^2[0-9]{2}$ ]]; then
        [[ "$VERBOSE" -eq 1 ]] && log_debug "HTTP: $url = $http_code"
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            jq -n --arg tipo "http" --arg nome "$url" --arg status "ok" --arg detalhes "HTTP $http_code" --arg ts "$timestamp" '{tipo: $tipo, nome: $nome, status: $status, detalhes: $detalhes, timestamp: $ts}'
        else
            printf '  \033[0;32m[OK]\033[0m  %s (HTTP %s)\n' "$url" "$http_code"
        fi
        return 0
    else
        local erro="timeout/erro de conexão"
        [[ $codigo -eq 0 ]] && erro="HTTP $http_code"
        [[ "$VERBOSE" -eq 1 ]] && log_aviso "HTTP: $url = $erro"
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            jq -n --arg tipo "http" --arg nome "$url" --arg status "fail" --arg detalhes "$erro" --arg ts "$timestamp" '{tipo: $tipo, nome: $nome, status: $status, detalhes: $detalhes, timestamp: $ts}'
        else
            printf '  \033[0;31m[FALHA]\033[0m %s - %s\n' "$url" "$erro"
        fi
        return 1
    fi
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -t|--timeout) TIMEOUT="${2:-}"; shift 2 ;;
            -s|--servicos) ARQ_SERVICOS="${2:-}"; shift 2 ;;
            -e|--endpoints) ARQ_ENDPOINTS="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) die "argumento não esperado: $1" 2 ;;
        esac
    done

    [[ "$TIMEOUT" =~ ^[0-9]+$ ]] && (( TIMEOUT > 0 )) || die "timeout deve ser número positivo: $TIMEOUT" 2

    # Pré-requisitos
    requer_comando systemctl
    requer_comando curl
    [[ "$JSON_OUTPUT" -eq 1 ]] && requer_comando jq

    log_info "início (json=$JSON_OUTPUT, timeout=${TIMEOUT}s, servicos=$ARQ_SERVICOS, endpoints=$ARQ_ENDPOINTS)"

    # Carrega listas
    local servicos endpoints
    mapfile -t servicos < <(ler_lista "$ARQ_SERVICOS" 2>/dev/null || true)
    mapfile -t endpoints < <(ler_lista "$ARQ_ENDPOINTS" 2>/dev/null || true)

    local total_checks=0 falhas=0
    local json_results="[]"

    # Verifica serviços systemd
    for svc in "${servicos[@]}"; do
        [[ -z "$svc" ]] && continue
        total_checks=$(( total_checks + 1 ))
        local resultado
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            resultado=$(verificar_systemd "$svc")
            json_results=$(echo "$json_results" | jq -c --argjson r "$resultado" '. + [$r]')
        else
            verificar_systemd "$svc" || falhas=$(( falhas + 1 ))
        fi
    done

    # Verifica endpoints HTTP
    for ep in "${endpoints[@]}"; do
        [[ -z "$ep" ]] && continue
        total_checks=$(( total_checks + 1 ))
        local resultado
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            resultado=$(verificar_http "$ep")
            json_results=$(echo "$json_results" | jq -c --argjson r "$resultado" '. + [$r]')
        else
            verificar_http "$ep" || falhas=$(( falhas + 1 ))
        fi
    done

    # Saída final
    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        local ok=$(( total_checks - falhas ))
        jq -n \
            --argjson total "$total_checks" \
            --argjson ok "$ok" \
            --argjson falhas "$falhas" \
            --argjson checks "$json_results" \
            --arg timestamp "$(date -Iseconds)" \
            '{timestamp: $timestamp, total: $total, ok: $ok, falhas: $falhas, verificacoes: $checks}'
    else
        echo
        log_info "Resumo: ${total_checks} verificações, $(( total_checks - falhas )) OK, ${falhas} FALHA"
    fi

    log_info "fim (falhas=$falhas)"
    [[ $falhas -eq 0 ]] || exit 1
}

main "$@"