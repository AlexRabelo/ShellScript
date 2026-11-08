#!/usr/bin/env bash
#
# funcoes-basicas.sh - Demonstração de definição de funções, escopo local e retorno
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   funcoes-basicas.sh
#
# Códigos de saída:
#   0  Sucesso
#
# Exemplos:
#   ./funcoes-basicas.sh
#
# Demonstra:
#   - Retorno de status (0 = sucesso, non-zero = falha)
#   - Retorno de valor via stdout ($(funcao))
#   - Escopo de variáveis com local
#   - Códigos de saída customizados com return
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

# --- Funções do Módulo ---

# Função 1: Retorno de status (0 = sucesso, 1 = falha)
eh_par() {
    local num="$1"
    [[ $(( num % 2 )) -eq 0 ]]
}

# Função 2: Retorno de valor via stdout
dobro() {
    local num="$1"
    echo $(( num * 2 ))
}

# Função 3: Vários retornos de status
classifica_numero() {
    local num="$1"
    if (( num > 0 )); then
        return 0  # Positivo
    elif (( num < 0 )); then
        return 1  # Negativo
    else
        return 2  # Zero
    fi
}

# Função 4: Demonstração de escopo LOCAL
contador_global=100

incrementa() {
    local contador_local=0
    contador_local=$(( contador_local + 1 ))
    echo "Local dentro da função: $contador_local"
    # contador_global NÃO foi alterado
}

# --- Lógica Principal --------------------------------------------------------
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

    echo "=== Demonstração de Funções ==="
    echo

    # Teste eh_par
    for n in 2 3 4 5; do
        if eh_par "$n"; then
            echo "$n é par"
        else
            echo "$n é ímpar"
        fi
    done

    echo

    # Teste dobro
    echo "Dobro de 7: $(dobro 7)"
    echo "Dobro de 15: $(dobro 15)"

    echo

    # Teste classifica_numero
    for n in -5 0 5; do
        if classifica_numero "$n"; then
            echo "$n -> Positivo (exit 0)"
        else
            codigo=$?
            if (( codigo == 1 )); then
                echo "$n -> Negativo (exit 1)"
            else
                echo "$n -> Zero (exit 2)"
            fi
        fi
    done

    echo

    # Teste escopo
    echo "contador_global ANTES: $contador_global"
    incrementa
    echo "contador_global DEPOIS: $contador_global"
    echo "(Perceba que a variável local não vazou)"

    log_info "fim"
}

main "$@"