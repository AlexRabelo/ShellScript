#!/usr/bin/env bash
#
# calculadora.sh - Demonstra aritmética em Bash com $(( ))
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   calculadora.sh NUM1 NUM2
#
# Argumentos:
#   NUM1    Primeiro número inteiro (obrigatório)
#   NUM2    Segundo número inteiro (obrigatório)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro: argumentos não são números inteiros
#   2  Uso incorreto
#
# Exemplos:
#   ./calculadora.sh 10 3
#   ./calculadora.sh -5 2
#
# Demonstra:
#   - Aritmética inteira com $(( ))
#   - Operadores: +, -, *, /, %, **
#   - Incremento pré e pós
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

    [[ $# -eq 2 ]] || { usage >&2; die "forneça exatamente 2 números" 2; }

    a="$1"
    b="$2"

    # Valida se são números inteiros
    [[ "$a" =~ ^-?[0-9]+$ ]] || { die "'$a' não é um número inteiro" 1; }
    [[ "$b" =~ ^-?[0-9]+$ ]] || { die "'$b' não é um número inteiro" 1; }

    echo "Operações com $a e $b:"
    echo "  Soma:       $(( a + b ))"
    echo "  Subtração:  $(( a - b ))"
    echo "  Multiplicação: $(( a * b ))"
    echo "  Divisão inteira: $(( a / b ))"
    echo "  Resto:      $(( a % b ))"
    echo "  Potência:   $(( a ** b ))"

    # Demonstra incremento
    contador=0
    (( contador++ ))
    echo "  Contador pós-incremento: $contador"

    (( ++contador ))
    echo "  Contador pré-incremento: $contador"

    log_info "fim"
}

main "$@"