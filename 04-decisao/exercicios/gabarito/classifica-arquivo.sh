#!/usr/bin/env bash
# classifica-arquivo.sh — Gabarito Exercício 1

[[ $# -ge 1 ]] || { echo "Uso: $0 CAMINHO" >&2; exit 2; }

caminho="$1"

if [[ ! -e "$caminho" ]]; then
    echo "Tipo: não existe"
elif [[ -f "$caminho" ]]; then
    echo "Tipo: arquivo regular"
elif [[ -d "$caminho" ]]; then
    echo "Tipo: diretório"
elif [[ -L "$caminho" ]]; then
    echo "Tipo: link simbólico"
elif [[ -S "$caminho" ]]; then
    echo "Tipo: socket"
elif [[ -p "$caminho" ]]; then
    echo "Tipo: pipe (FIFO)"
elif [[ -b "$caminho" ]]; then
    echo "Tipo: bloco"
elif [[ -c "$caminho" ]]; then
    echo "Tipo: caractere"
else
    echo "Tipo: outro"
fi