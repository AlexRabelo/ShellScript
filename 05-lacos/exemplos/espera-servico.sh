#!/usr/bin/env bash
#
# espera-servico.sh - Aguarda uma porta TCP abrir (retry loop com timeout)
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   espera-servico.sh HOST PORTA [TIMEOUT_SEGUNDOS]
#
# Argumentos:
#   HOST               Hostname ou IP do servidor (obrigatório)
#   PORTA              Número da porta TCP (obrigatório, 1-65535)
#   TIMEOUT_SEGUNDOS   Timeout total em segundos (opcional, padrão: 30)
#
# Códigos de saída:
#   0  Sucesso (porta abriu)
#   1  Timeout (porta não abriu no tempo limite)
#   2  Uso incorreto / argumentos inválidos
#
# Exemplos:
#   ./espera-servico.sh localhost 5432
#   ./espera-servico.sh db.exemplo.com 3306 60
#
# Demonstra:
#   - Loop while com condição de tempo
#   - Backoff exponencial
#   - Teste de porta TCP com /dev/tcp
#   - Padrão "wait-for-it" simplificado
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

cleanup() {
    local codigo=$?
    if [[ $codigo -eq 0 ]]; then
        log_info "terminou com sucesso"
    else
        log_erro "terminou com falha (código ${codigo})"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] $*"
        return 0
    else
        log_debug "executando: $*"
        "$@"
    fi
}

usage() {
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE)"

    [[ $# -ge 2 ]] || { usage >&2; die "forneça HOST PORTA [TIMEOUT]" 2; }

    host="$1"
    porta="$2"
    timeout="${3:-30}"

    # Validações
    if [[ ! "$porta" =~ ^[0-9]+$ ]] || (( porta < 1 || porta > 65535 )); then
        die "Porta inválida: $porta" 2
    fi
    [[ "$timeout" =~ ^[0-9]+$ ]] || { die "Timeout inválido: $timeout" 2; }

    inicio=$(date +%s)
    fim=$(( inicio + timeout ))
    tentativa=0

    echo "Aguardando $host:$porta por até $timeout segundos..."

    while (( $(date +%s) < fim )); do
        (( tentativa++ ))
        if timeout 1 bash -c "cat < /dev/null > /dev/tcp/$host/$porta" 2>/dev/null; then
            decorrido=$(( $(date +%s) - inicio ))
            echo "Sucesso! Porta $host:$porta aberta após $tentativa tentativa(s) (${decorrido}s)."
            exit 0
        fi

        # Backoff exponencial simples: 1s, 2s, 3s... (máx 5s)
        pausa=$(( tentativa < 5 ? tentativa : 5 ))
        echo "Tentativa $tentativa: porta fechada. Aguardando ${pausa}s..."
        sleep "$pausa"
    done

    decorrido=$(( $(date +%s) - inicio ))
    die "TIMEOUT: Porta $host:$porta não abriu após $decorrido segundos (máx $timeout)" 1
}

main "$@"