#!/usr/bin/env bash
# valida-numero.sh — Gabarito Exercício 5

[[ $# -ge 1 ]] || { echo "Uso: $0 NUMERO" >&2; exit 2; }

num="$1"

if [[ ! "$num" =~ ^[0-9]+$ ]]; then
    echo "Erro: '$num' não é número positivo" >&2
    exit 2
fi

if (( num > 1000 )); then
    echo "Faixa: > 1000"
elif (( num > 100 )); then
    echo "Faixa: 101-1000"
else
    echo "Faixa: 0-100"
fi