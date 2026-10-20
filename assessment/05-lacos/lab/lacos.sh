#!/usr/bin/env bash
# Lab: Módulo 05 — Laços
# Tempo: 20 min | Objetivo: Retry loop robusto com backoff exponencial + validação

# =============================================================================
# ENUNCIADO
# =============================================================================
# Crie `retry-curl.sh` que:
# 1. Recebe: URL + max_tentativas (padrão 5) + timeout_por_tentativa (padrão 10s)
# 2. Flags: -v (verbose), -n (dry-run), -h (help)
# 3. Usa curl com --max-time e --connect-timeout
# 4. Backoff exponencial: 1s, 2s, 4s, 8s, 16s... (teto 30s)
# 5. Sucesso: HTTP 2xx; Falha: outro código ou timeout
# 6. Log estruturado com timestamp, nível, tentativa, código HTTP
# 7. Passa shellcheck

# =============================================================================
# SOLUÇÃO COMPLETA
# =============================================================================

set -Eeuo pipefail

URL=""
MAX_TENTATIVAS=5
TIMEOUT=10
VERBOSE=0
DRY_RUN=0

usage() {
    cat <<'EOF'
retry-curl - Retry HTTP com backoff exponencial

Uso: retry-curl.sh [-t N] [-T SEG] [-v] [-n] URL

Opções:
  -t N          Max tentativas (padrão: 5)
  -T SEG        Timeout por tentativa em segundos (padrão: 10)
  -v            Verbose (mostra headers curl)
  -n            Dry-run
  -h            Ajuda

Exemplos:
  retry-curl.sh https://api.exemplo.com/health
  retry-curl.sh -t 3 -T 5 -v https://site.com
EOF
}

valida_url() {
    local url="$1"
    [[ "$url" =~ ^https?:// ]] || return 1
    return 0
}

log() {
    local nivel="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo "${timestamp} [${nivel}] [PID:$$] ${msg}"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_erro() { log "ERROR" "$@"; }
log_debug() { (( VERBOSE )) && log "DEBUG" "$@"; }

http_request() {
    local url="$1"
    local timeout="$2"
    local verbose_flag=""

    (( VERBOSE )) && verbose_flag="-v"

    if (( DRY_RUN )); then
        log_info "[DRY-RUN] curl --max-time ${timeout} --connect-timeout 5 ${verbose_flag} -s -o /dev/null -w \"%{http_code}\" \"${url}\""
        echo "200"
        return 0
    fi

    local http_code
    http_code=$(curl ${verbose_flag} -s --max-time "${timeout}" --connect-timeout 5 -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")
    echo "${http_code}"
}

backoff() {
    local tentativa="$1"
    local delay=$(( 2 ** (tentativa - 1) ))
    (( delay > 30 )) && delay=30
    echo "$delay"
}

main() {
    local opt
    while getopts "t:T:vnh" opt; do
        case $opt in
            t) MAX_TENTATIVAS="$OPTARG" ;;
            T) TIMEOUT="$OPTARG" ;;
            v) VERBOSE=1 ;;
            n) DRY_RUN=1 ;;
            h) usage; exit 0 ;;
            *) usage >&2; exit 2 ;;
        esac
    done
    shift $((OPTIND-1))

    URL="${1:-}"

    # Validações
    [[ -z "$URL" ]] && { echo "Erro: URL obrigatória" >&2; usage >&2; exit 2; }
    valida_url "$URL" || { echo "Erro: URL inválida (deve começar com http:// ou https://)" >&2; exit 2; }
    [[ "$MAX_TENTATIVAS" =~ ^[1-9][0-9]*$ ]] || { echo "Erro: -t deve ser inteiro positivo" >&2; exit 2; }
    [[ "$TIMEOUT" =~ ^[1-9][0-9]*$ ]] || { echo "Erro: -T deve ser inteiro positivo" >&2; exit 2; }

    log_info "início (url=$URL, max=$MAX_TENTATIVAS, timeout=$TIMEOUT)"
    (( DRY_RUN )) && log_info "=== MODO DRY-RUN ==="

    local tentativa=0
    local http_code=000

    while (( tentativa < MAX_TENTATIVAS )); do
        ((tentativa++))
        log_debug "Tentativa $tentativa de $MAX_TENTATIVAS"

        http_code=$(http_request "$URL" "$TIMEOUT")

        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            log_info "SUCESSO: HTTP $http_code na tentativa $tentativa"
            exit 0
        fi

        log_warn "Tentativa $tentativa falhou (HTTP $http_code)"

        if (( tentativa == MAX_TENTATIVAS )); then
            log_erro "Todas as $MAX_TENTATIVAS tentativas falharam. Último código: $http_code"
            exit 1
        fi

        local pausa
        pausa=$(backoff "$tentativa")
        log_warn "Aguardando ${pausa}s antes da próxima tentativa..."

        if (( DRY_RUN )); then
            log_info "[DRY-RUN] sleep $pausa"
        else
            sleep "$pausa"
        fi
    done
}

main "$@"