#!/usr/bin/env bash
#
# mostra-env.sh - mostra o valor de uma variável de ambiente.
#
# Uso: ./mostra-env.sh NOME_DA_VARIAVEL

[[ $# -eq 1 ]] || { echo "Uso: $0 NOME_DA_VARIAVEL" >&2; exit 2; }

var_nome="$1"

# Usa printenv (mais simples e portável)
if printenv "$var_nome" >/dev/null 2>&1; then
    printenv "$var_nome"
    exit 0
else
    echo "Variável não definida: $var_nome" >&2
    exit 1
fi

# Alternativa com expansão indireta (Bash 4.3+):
# declare -n var_ref="$var_nome" 2>/dev/null || { echo "Variável não definida: $var_nome" >&2; exit 1; }
# echo "${var_ref}"