#!/usr/bin/env bash
#
# valida-entrada.sh - demonstra validação de entrada do usuário.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   valida-entrada.sh
#
# O script pede ao usuário para inserir um nome, idade e email,
# validando cada entrada antes de prosseguir.
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

    # Funções auxiliares
    coletar_hostname() {
        hostname
    }

    # Lógica principal do script vai aqui
    # Exemplo:
    # for arg in "$@"; do
    #     log_info "Processando: $arg"
    # done

    local nome idade email
    local tentativas=0
    local max_tentativas=3

    echo "=== Validação de Entrada do Usuário ==="
    echo

    # Validação do nome (não vazio)
    while [[ $tentativas -lt $max_tentativas ]]; do
        read -rp "Nome completo: " nome
        if [[ -n "$nome" ]]; then
            break
        else
            ((tentativas++))
            if [[ $tentativas -lt $max_tentativas ]]; then
                echo "Erro: Nome não pode estar vazio. Tentativa $tentativas/$max_tentativas" >&2
            fi
        fi
    done

    if [[ $tentativas -eq $max_tentativas ]]; then
        die "Número máximo de tentativas excedido para nome" 1
    fi

    tentativas=0

    # Validação da idade (número entre 1 e 100)
    while [[ $tentativas -lt $max_tentativas ]]; do
        read -rp "Idade (1-100): " idade
        if [[ "$idade" =~ ^[0-9]+$ ]] && (( idade >= 1 && idade <= 100 )); then
            break
        else
            ((tentativas++))
            if [[ $tentativas -lt $max_tentativas ]]; then
                echo "Erro: Idade deve ser um número entre 1 e 100. Tentativa $tentativas/$max_tentativas" >&2
            fi
        fi
    done

    if [[ $tentativas -eq $max_tentativas ]]; then
        die "Número máximo de tentativas excedido para idade" 1
    fi

    tentativas=0

    # Validação do email (formato básico)
    while [[ $tentativas -lt $max_tentativas ]]; do
        read -rp "Email: " email
        if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            ((tentativas++))
            if [[ $tentativas -lt $max_tentativas ]]; then
                echo "Erro: Email inválido. Tentativa $tentativas/$max_tentativas" >&2
            fi
        fi
    done

    if [[ $tentativas -eq $max_tentativas ]]; then
        die "Número máximo de tentativas excedido para email" 1
    fi

    echo
    echo "=== Dados Validados ==="
    echo "Nome:  $nome"
    echo "Idade: $idade anos"
    echo "Email: $email"

    log_info "fim"
}

main "$@"