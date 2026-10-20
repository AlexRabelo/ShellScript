#!/usr/bin/env bash
#
# status-servico.sh - verifica o status de um serviço systemd.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   status-servico.sh NOME_DO_SERVICO
#
# Verifica se um serviço systemd está ativo, inativo ou falhou.
# Usa systemctl is-active para verificar o status.
#
# Exemplo:
#   status-servico.sh ssh
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

    # Verifica pré-requisitos
    requer_comando systemctl

    [[ $# -eq 1 ]] || { usage >&2; die "forneça exatamente 1 argumento (nome do serviço)" 2; }

    servico="$1"

    # Verifica se o serviço existe
    if ! systemctl list-unit-files "${servico}.service" >/dev/null 2>&1; then
        log_erro "Serviço '${servico}' não encontrado"
        exit 1
    fi

    # Verifica o status do serviço
    if systemctl is-active --quiet "${servico}.service"; then
        echo "Serviço ${servico}: ATIVO"
        exit 0
    elif systemctl is-failed --quiet "${servico}.service"; then
        echo "Serviço ${servico}: FALHOU"
        exit 2
    else
        echo "Serviço ${servico}: INATIVO"
        exit 1
    fi

    log_info "fim"
}

main "$@"