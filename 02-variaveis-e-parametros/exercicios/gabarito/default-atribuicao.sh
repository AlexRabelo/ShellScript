#!/usr/bin/env bash
# default-atribuicao.sh — Gabarito Exercício 2

dir=""
echo "Antes: '${dir}'"
echo "Usando: ${dir:=/tmp/meuapp}"
echo "Depois: '${dir}'"

mkdir -p "$dir"
echo "Diretório criado: $dir"