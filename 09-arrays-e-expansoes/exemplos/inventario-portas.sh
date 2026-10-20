#!/usr/bin/env bash
#
# inventario-portas.sh - array associativo mapeando serviço -> porta padrão.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   inventario-portas.sh [SERVIÇO]
#
# Demonstra declare -A, iteração, lookup e validação.
# Se nenhum argumento for passado, lista todos os serviços e portas.
# Se um serviço for passado, mostra apenas a porta desse serviço.
#
# Exemplo:
#   inventario-portas.sh
#   inventario-portas.sh ssh
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg
    msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

die() {
    local msg="$1"
    local codigo
    codigo="${2:-1}"
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
    sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
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

    # Validação de argumentos vai aqui
    # Exemplo: [[ $# -eq 2 ]] || { usage >&2; die "forneça exatamente 2 argumentos" 2; }

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE)"

    # Lógica principal do script vai aqui
    # Exemplo:
    # for arg in "$@"; do
    #     log_info "Processando: $arg"
    # done

    # Array associativo: serviço -> porta padrão
    declare -A PORTAS_PADRAO=(
        [ssh]=22
        [http]=80
        [https]=443
        [ftp]=21
        [smtp]=25
        [dns]=53
        [dhcp]=67
        [ldap]=389
        [mysql]=3306
        [postgres]=5432
        [redis]=6379
        [mongodb]=27017
        [kafka]=9092
        [zookeeper]=2181
        [etcd]=2379
        [consul]=8500
        [vault]=8200
        [prometheus]=9090
        [grafana]=3000
        [jenkins]=8080
    )

    # Se argumento passado, mostra apenas aquele
    if [[ $# -eq 1 ]]; then
        local servico="$1"
        if [[ -v PORTAS_PADRAO["$servico"] ]]; then
            echo "${PORTAS_PADRAO[$servico]}"
        else
            log_erro "Serviço '$servico' não encontrado"
            exit 1
        fi
        exit 0
    fi

    # Caso contrário, lista todos
    echo "=== Inventário de Portas Padrão ==="
    printf "%-20s %s\n" "SERVIÇO" "PORTA"
    printf "%-20s %s\n" "-------" "-----"

    for servico in "${!PORTAS_PADRAO[@]}"; do
        printf "%-20s %d\n" "$servico" "${PORTAS_PADRAO[$servico]}"
    done | sort

    echo
    echo "Total: ${#PORTAS_PADRAO[@]} serviços"

    # Demonstra verificação de porta em uso
    echo
    echo "=== Verificação de Portas em Uso (ss -tunl) ==="
    for porta in "${PORTAS_PADRAO[@]}"; do
        if ss -tunl | grep -q ":$porta "; then
            echo "  Porta $porta: EM USO"
        fi
    done

    log_info "fim"
}

main "$@"