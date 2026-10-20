#!/usr/bin/env bash
#
# tabuada.sh - imprime tabuada de um número.
#
# Uso: ./tabuada.sh NUMERO

[[ $# -eq 1 ]] || { echo "Uso: $0 NUMERO" >&2; exit 2; }

num="$1"
[[ "$num" =~ ^-?[0-9]+$ ]] || { echo "ERRO: '$num' não é inteiro" >&2; exit 1; }

echo "Tabuada do $num:"
for i in {1..10}; do
    echo "$num x $i = $(( num * i ))"
done