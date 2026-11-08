#!/usr/bin/env bash
#
# spinner.sh - wrapper de execução com spinner animado.
#
# Uso: ./spinner.sh "Mensagem" COMANDO [ARGS...]

set -Eeuo pipefail

spinner_pid=0

inicia_spinner() {
    local msg="$1"
    local spin_chars='|/-\'
    local i=0

    # Esconde cursor
    tput civis 2>/dev/null || true

    (
        while true; do
            printf "\r${spin_chars:i++%${#spin_chars}:1} %s" "$msg"
            sleep 0.1
        done
    ) &

    spinner_pid=$!
}

para_spinner() {
    local exit_code="${1:-0}"
    local msg="$2"

    # Mata spinner
    kill "$spinner_pid" 2>/dev/null || true
    wait "$spinner_pid" 2>/dev/null || true

    # Restaura cursor
    tput cnorm 2>/dev/null || true

    if (( exit_code == 0 )); then
        printf "\r\033[K✓ %s\n" "$msg"
    else
        printf "\r\033[K✗ %s (exit %d)\n" "$msg" "$exit_code" >&2
    fi
}

executa_com_spinner() {
    local msg="$1"
    shift

    inicia_spinner "$msg"

    # Executa comando em background
    "$@" &
    local cmd_pid=$!

    # Aguarda comando terminar
    wait "$cmd_pid"
    local codigo=$?

    para_spinner "$codigo" "$msg"
    return "$codigo"
}

# Teste se executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== Teste do Spinner ==="
    echo
    executa_com_spinner "Dormindo 2 segundos" sleep 2
    executa_com_spinner "Listando /etc" ls /etc >/dev/null
    executa_com_spinner "Comando que falha" false
fi