#!/usr/bin/env bash
#
# lista-servidores.sh - Testa conectividade (ping) em lista de servidores
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   lista-servidores.sh [ARQUIVO_HOSTS]
#
# Argumentos:
#   ARQUIVO_HOSTS   Arquivo com lista de hosts (um por linha) (opcional)
#
# Códigos de saída:
#   0  Todos os hosts estão online
#   1  Pelo menos um host está offline
#   2  Uso incorreto
#
# Exemplos:
#   ./lista-servidores.sh
#   ./lista-servidores.sh hosts.txt
#
# Demonstra:
#   - Arrays (definição e leitura via mapfile)
#   - Loop for sobre array
#   - Contadores e relatório final
#   - Teste de conectividade com ping
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

    # Array de servidores (pode vir de arquivo ou ser definido aqui)
    local SERVIDORES=()
    if [[ $# -eq 1 && -f "$1" ]]; then
        mapfile -t SERVIDORES < "$1"
    else
        SERVIDORES=(
            "8.8.8.8"
            "1.1.1.1"
            "192.168.99.99"   # IP inexistente para testar falha
            "google.com"
            "github.com"
        )
    fi

    echo "=== Teste de Conectividade (Ping) ==="
    echo "Total de alvos: ${#SERVIDORES[@]}"
    echo

    local online=0
    local offline=0

    for host in "${SERVIDORES[@]}"; do
        printf "Testando %-20s ... " "$host"
        if [[ "$DRY_RUN" -eq 0 ]]; then
            if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
                echo "ONLINE"
                (( online++ ))
            else
                echo "OFFLINE"
                (( offline++ ))
            fi
        else
            log_info "[DRY-RUN] ping -c 1 -W 2 $host"
        fi
    done

    echo
    echo "=== Resumo ==="
    echo "Online:  $online"
    echo "Offline: $offline"

    # Saída com código indicando se houve falhas
    [[ $offline -eq 0 ]] && exit 0 || exit 1
}

main "$@"