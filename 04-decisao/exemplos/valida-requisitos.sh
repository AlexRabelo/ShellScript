#!/usr/bin/env bash
#
# valida-requisitos.sh - verifica pré-requisitos para execução de script.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   valida-requisitos.sh
#
# Verifica se o script está sendo executado como root, se os comandos necessários
# estão disponíveis e se o sistema operacional é suportado.
#
# Exemplo:
#   valida-requisitos.sh
#
# =============================================================================

set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

# --- Funções de Log ----------------------------------------------------------
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

# --- Limpeza e Tratamento de Sinais ------------------------------------------
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

# --- Utilidades --------------------------------------------------------------
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

    # Lógica principal do script vai aqui
    # Exemplo:
    # for arg in "$@"; do
    #     log_info "Processando: $arg"
    # done

    # Verifica se está sendo executado como root
    if [[ $EUID -ne 0 ]]; then
        log_aviso "Este script precisa ser executado como root para funcionalidade completa"
        # Não termina o script, apenas avisa
    fi

    # Lista de comandos necessários
    local comandos_necessarios=("ls" "df" "awk" "systemctl" "hostname" "uname")
    local comandos_faltando=()

    for cmd in "${comandos_necessarios[@]}"; do
        if ! comando_existe "$cmd"; then
            comandos_faltando+=("$cmd")
        fi
    done

    if [[ ${#comandos_faltando[@]} -gt 0 ]]; then
        log_erro "Os seguintes comandos estão faltando: ${comandos_faltando[*]}"
        exit 3
    fi

    # Verifica distribuição Linux
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        log_info "Distribuição detectada: $PRETTY_NAME"
    else
        log_aviso "Não foi possível detectar a distribuição Linux"
    fi

    echo "Verificação de pré-requisitos concluída"
    [[ $EUID -eq 0 ]] && echo "✓ Executando como root" || echo "✗ Não está executando como root (algumas funcionalidades podem estar limitadas)"
    echo "✓ Todos os comandos necessários estão disponíveis"

    log_info "fim"
}

# Função auxiliar para verificar se comando existe (não usa die para permitir uso em validações)
comando_existe() {
    command -v "$1" > /dev/null 2>&1
}

main "$@"