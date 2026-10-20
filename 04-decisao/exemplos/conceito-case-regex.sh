#!/usr/bin/env bash
# conceito-case-regex.sh — case com regex via [[ ]] (versão didática)

entrada="${1:-Sim}"

echo "=== case NÃO suporta regex nativamente ==="
echo "Use if/elif com =~ para regex:"

if [[ "$entrada" =~ ^[Ss][Ii][Mm]$ ]]; then
    echo "Detectou 'sim' (regex case-insensitive)"
elif [[ "$entrada" =~ ^[Nn][Aa][Oo]$ ]]; then
    echo "Detectou 'não' (regex case-insensitive)"
elif [[ "$entrada" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo "Detectou 'yes' ou 'y' (regex)"
else
    echo "Não reconhecido: '$entrada'"
fi

echo
echo "=== Alternativa: shopt nocasematch + case ==="
shopt -s nocasematch
case "$entrada" in
    sim) echo "sim (nocasematch)";;
    nao|não) echo "não (nocasematch)";;
    yes|y) echo "yes/y (nocasematch)";;
    *) echo "não reconhecido (nocasematch)";;
esac
shopt -u nocasematch