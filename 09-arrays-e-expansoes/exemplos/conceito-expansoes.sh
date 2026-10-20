#!/usr/bin/env bash
# conceito-expansoes.sh — Expansões de parâmetro (versão didática)

path="/home/usuario/documentos/arquivo.txt"
arquivo="backup.tar.gz"
frase="  hello world  "
url="https://exemplo.com/caminho"

echo "=== Path manipulation (# ## % %%) ==="
echo "path: $path"
echo "basename (##*/): ${path##*/}"
echo "dirname (%/*): ${path%/*}"
echo "extensão (.%%) : ${arquivo%%.*}"
echo "sem extensão (%.*): ${arquivo%.*}"

echo
echo "=== Substituição (/ //) ==="
echo "frase: '$frase'"
echo "1º espaço -> _ : '${frase/ /_}'"
echo "todos espaços -> _ : '${frase// /_}'"
echo "remove espaços: '${frase// /}'"

echo
echo "=== Case (^^ ^^ ,, ,,) ==="
palavra="BaSh"
echo "original: $palavra"
echo "^^ (todas maiúsculas): ${palavra^^}"
echo ",, (todas minúsculas): ${palavra,,}"
echo "^ (1ª maiúscula): ${palavra^}"
echo ", (1ª minúscula): ${palavra,}"

echo
echo "=== Substring (:pos:len) ==="
echo "url: $url"
echo ":8 (a partir do 8): ${url:8}"
echo ":8:5 (5 chars a partir do 8): ${url:8:5}"
echo ":-5 (últimos 5): ${url: -5}"  # espaço antes de - obrigatório

echo
echo "=== Comprimento ==="
echo "frase: '$frase' -> tamanho: ${#frase}"