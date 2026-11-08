#!/usr/bin/env bash
#
# lib/eh_numero.sh - valida se string é número inteiro.
#
# Uso: source eh_numero.sh
#      eh_numero "STRING" && echo "É número" || echo "Não é número"

eh_numero() {
    local str="${1:-}"
    # Regex: opcional sinal -, seguido de 1+ dígitos
    [[ "$str" =~ ^-?[0-9]+$ ]]
}

# Se executado diretamente, permite teste rápido
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    for test in "42" "-10" "0" "3.14" "abc" "" "1e5"; do
        if eh_numero "$test"; then
            echo "  '$test' -> É NÚMERO"
        else
            echo "  '$test' -> NÃO É NÚMERO"
        fi
    done
fi