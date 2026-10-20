#!/usr/bin/env bash
# path-expansao.sh — Gabarito Exercício 1

[[ $# -ge 1 ]] || { echo "Uso: $0 CAMINHO" >&2; exit 2; }

caminho="$1"

dir="${caminho%/*}"
arquivo="${caminho##*/}"
base="${arquivo%.*}"
ext="${arquivo#*.}"

echo "Diretório: $dir"
echo "Arquivo: $arquivo"
echo "Base: $base"
echo "Extensão: $ext"