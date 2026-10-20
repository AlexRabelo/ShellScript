#!/usr/bin/env bash
#
# lib/retry.sh - função genérica de retry com backoff.
#
# Uso: source lib/retry.sh
#      retry 3 2 curl -fsS http://api/health

retry() {
    local max_tentativas="${1:-3}"
    local intervalo="${2:-2}"
    shift 2

    local tentativa=0
    local saida
    local codigo

    while (( tentativa < max_tentativas )); do
        (( tentativa++ ))
        saida=$("$@" 2>&1)
        codigo=$?

        if (( codigo == 0 )); then
            echo "$saida"
            return 0
        fi

        if (( tentativa < max_tentativas )); then
            echo "Tentativa $tentativa/$max_tentativas falhou (exit $codigo). Retentando em ${intervalo}s..." >&2
            sleep "$intervalo"
        fi
    done

    echo "Todas as $max_tentativas tentativas falharam. Último erro: $saida" >&2
    return "$codigo"
}

# Teste se executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    retry 3 1 false
    echo "Exit code: $?"
fi