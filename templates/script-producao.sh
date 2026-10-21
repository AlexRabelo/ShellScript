#!/usr/bin/env bash
#
# NOME.sh - descrição em uma linha do que o script faz.
#
# Uso:
#   NOME.sh [-n] [-v] [-h] ARGUMENTO
#
# Opções:
#   -n   dry-run: mostra o que faria, sem alterar nada
#   -v   verboso (nível DEBUG)
#   -h   exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro genérico | 2 uso incorreto | 3 pré-requisito ausente
#
# Este template usa conceitos dos módulos 02 a 10. Se algo parecer estranho,
# volte ao módulo correspondente.

# --- Modo estrito ------------------------------------------------------------
# -e: aborta em erro | -u: erro em variável não definida | pipefail: pipe falha se qualquer parte falhar
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.sh}.lock"

DRY_RUN=0
VERBOSE=0
TMP_DIR=""

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local linha
    linha="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$linha" >> "$LOG_FILE"
    # Erros e avisos vão para stderr; o resto para stdout
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$linha" >&2 ;;
        DEBUG)      [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$linha" ;;
        *)          printf '%s\n' "$linha" ;;
    esac
    return 0
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

# --- Limpeza e tratamento de falhas ------------------------------------------
cleanup() {
    local codigo=$?
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf -- "$TMP_DIR"
    fi
    if [[ "$codigo" -ne 0 ]]; then
        log_erro "terminou com falha (código ${codigo})"
    else
        log_info "terminou com sucesso"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Ajuda -------------------------------------------------------------------
usage() {
    # Mostra o cabeçalho de comentários do próprio arquivo (linhas 3 a 15)
    sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Utilidades --------------------------------------------------------------
# Executa o comando, ou apenas o exibe em modo dry-run.
run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[dry-run] $*"
    else
        log_debug "executando: $*"
        "$@"
    fi
}

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

# --- Lógica principal --------------------------------------------------------
main() {
    local argumento

    while getopts ':nvh' opcao; do
        case "$opcao" in
            n) DRY_RUN=1 ;;
            v) VERBOSE=1 ;;
            h) usage; exit 0 ;;
            *) usage >&2; die "opção inválida: -${OPTARG}" 2 ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ $# -eq 1 ]] || { usage >&2; die "informe exatamente 1 argumento" 2; }
    argumento="$1"

    requer_comando date
    requer_comando mktemp
    requer_comando flock

    # Impede duas execuções ao mesmo tempo
    exec 9> "$LOCK_FILE"
    flock -n 9 || die "já existe outra execução em andamento" 1

    TMP_DIR="$(mktemp -d)"
    log_info "início (argumento=${argumento}, dry-run=${DRY_RUN})"

    # ----- Sua lógica começa aqui -----
    run echo "processando ${argumento}"
    # ----- Sua lógica termina aqui ----
}

main "$@"
