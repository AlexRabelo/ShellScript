#!/usr/bin/env bash
#
# contador.sh - conta de um inicial até um limite usando aritmética.
#
# Uso: ./contador.sh [INICIAL] [LIMITE]

inicial="${1:-0}"
limite="${2:-10}"

# Valida números inteiros
[[ "$inicial" =~ ^-?[0-9]+$ ]] || { echo "Erro: inicial deve ser inteiro" >&2; exit 1; }
[[ "$limite" =~ ^-?[0-9]+$ ]] || { echo "Erro: limite deve ser inteiro" >&2; exit 1; }

echo "Contando de $inicial até $limite:"
soma=0
for (( i = inicial; i <= limite; i++ )); do
    echo -n "$i "
    (( soma += i ))
done
echo
echo "Soma total: $soma"