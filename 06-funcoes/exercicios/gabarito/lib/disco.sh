#!/usr/bin/env bash
#
# lib/disco.sh - verificação de uso de disco reutilizável.
#
# Uso: source lib/disco.sh
#      verifica_disco "/mnt/dados" 80 90
#      echo "Status: $?"

verifica_disco() {
    local ponto="${1:-/}"
    local aviso="${2:-80}"
    local critico="${3:-90}"

    # Valida parâmetros
    [[ "$aviso" =~ ^[0-9]+$ ]] && [[ "$critico" =~ ^[0-9]+$ ]] || return 3
    (( aviso < critico )) || return 3

    # Verifica se ponto de montagem existe
    if ! df "$ponto" >/dev/null 2>&1; then
        return 3
    fi

    local uso
    uso=$(df "$ponto" | awk 'NR==2 {print $5}' | tr -d '%')

    if (( uso >= critico )); then
        echo "CRÍTICO: $ponto em ${uso}% (limiar $critico%)" >&2
        return 2
    elif (( uso >= aviso )); then
        echo "AVISO: $ponto em ${uso}% (limiar $aviso%)" >&2
        return 1
    else
        echo "OK: $ponto em ${uso}%"
        return 0
    fi
}

# Teste se executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    verifica_disco "/" 80 90
    echo "Exit code: $?"
fi