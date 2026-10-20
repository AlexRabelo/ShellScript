#!/usr/bin/env bash
#
# cria-dir-data.sh - cria um diretório com data no nome.
#
# Uso: ./cria-dir-data.sh

read -p "Nome base do diretório: " nome_base
[[ -n "$nome_base" ]] || { echo "Nome não pode ser vazio" >&2; exit 1; }

read -p "Destino [/tmp]: " destino
destino="${destino:-/tmp}"

data="$(date +%F)"   # YYYY-MM-DD
dir_completo="${destino}/${nome_base}-${data}"

mkdir -p "$dir_completo"

echo "Diretório criado: $dir_completo"
ls -ld "$dir_completo"