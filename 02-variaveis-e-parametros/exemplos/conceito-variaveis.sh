#!/usr/bin/env bash
# conceito-variaveis.sh — Atribuição, expansão, defaults (versão didática)

nome="servidor-web"
porta=443
ip=""

echo "=== Atribuição e leitura básica ==="
echo "nome=$nome"
echo "porta=$porta"

echo
echo "=== Expansão com default (:-) — não altera a variável ==="
echo "IP atual: '${ip}'"
echo "Usando default: ${ip:-127.0.0.1}"
echo "IP depois: '${ip}'"  # continua vazio

echo
echo "=== Expansão com atribuição (:=) — ALTERA a variável ==="
echo "IP antes: '${ip}'"
echo "Usando e setando: ${ip:=192.168.1.10}"
echo "IP depois: '${ip}'"  # agora tem valor

echo
echo "=== Expansão condicional (:+): usa valor SE a var tem conteúdo ==="
vazio=""
cheio="tem valor"
echo "vazio:+X -> '${vazio:+X}'"      # vazio
echo "cheio:+X -> '${cheio:+X}'"      # X

echo
echo "=== Tamanho da string ==="
msg="hello"
echo "Tamanho de '$msg': ${#msg}"