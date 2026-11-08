#!/usr/bin/env bash
#
# compara-numeros.sh - Demonstra comparações numéricas e de string
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   compara-numeros.sh NUM1 NUM2
#
# Argumentos:
#   NUM1    Primeiro número inteiro (obrigatório)
#   NUM2    Segundo número inteiro (obrigatório)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto / argumentos inválidos
#
# Exemplos:
#   ./compara-numeros.sh 10 5
#   ./compara-numeros.sh 3 3
#
# Demonstra:
#   - Comparações numéricas com [[ ]]: -eq, -ne, -lt, -le, -gt, -ge
#   - Comparações de string com [[ ]]: =, !=, <, >
#   - Aritmética com (( )): ==, !=, <, <=, >, >=
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

    # Valida se são números
    [[ "$1" =~ ^[0-9]+$ ]] || die "O primeiro argumento deve ser um número inteiro" 2
    [[ "$2" =~ ^[0-9]+$ ]] || die "O segundo argumento deve ser um número inteiro" 2

    num1="$1"
    num2="$2"

    echo "Comparando $num1 e $num2"
    echo

    # Comparações numéricas
    if [[ $num1 -eq $num2 ]]; then
        echo "$num1 é igual a $num2"
    else
        echo "$num1 é diferente de $num2"
    fi

    if [[ $num1 -lt $num2 ]]; then
        echo "$num1 é menor que $num2"
    elif [[ $num1 -gt $num2 ]]; then
        echo "$num1 é maior que $num2"
    fi

    if [[ $num1 -le $num2 ]]; then
        echo "$num1 é menor ou igual a $num2"
    fi

    if [[ $num1 -ge $num2 ]]; then
        echo "$num1 é maior ou igual a $num2"
    fi

    # Comparações de string (ordem alfabética)
    if [[ "$num1" = "$num2" ]]; then
        echo "\"$num1\" é igual a \"$num2\" (string)"
    else
        echo "\"$num1\" é diferente de \"$num2\" (string)"
    fi

    if [[ "$num1" < "$num2" ]]; then
        echo "\"$num1\" vem antes de \"$num2\" em ordem alfabética"
    elif [[ "$num1" > "$num2" ]]; then
        echo "\"$num1\" vem depois de \"$num2\" em ordem alfabética"
    fi

    # Usando aritmética com (( ))
    echo
    echo "Usando sintaxe aritmética (( )):"
    if (( num1 == num2 )); then
        echo "$num1 é igual a $num2"
    fi

    if (( num1 < num2 )); then
        echo "$num1 é menor que $num2"
    fi

    if (( num1 > num2 )); then
        echo "$num1 é maior que $num2"
    fi

    log_info "fim"
}

main "$@"