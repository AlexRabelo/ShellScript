#!/usr/bin/env bash
# conceito-read.sh — Ler entrada com read (versão didática)

echo "=== read -r -p (prompt inline) ==="
read -r -p "Seu nome: " nome
echo "Olá, $nome!"

echo
echo "=== read -r (raw — não interpreta \\) ==="
read -r -p "Caminho (com \\): " caminho
echo "Você digitou: $caminho"

echo
echo "=== read -r -s (silencioso — senha) ==="
read -r -s -p "Senha: " senha
echo
echo "Senha lida (tamanho: ${#senha})"

echo
echo "=== read -r -t (timeout) ==="
echo "Tem 3 segundos para digitar..."
if read -r -t 3 -p "Digite algo: " rapido; then
    echo "Você digitou: $rapido"
else
    echo "Tempo esgotado!"
fi

echo
echo "=== read -r -n 1 (um caractere) ==="
read -r -n 1 -p "Continuar? [s/N] " resp
echo
[[ "$resp" =~ [Ss] ]] && echo "Continuando..." || echo "Cancelado."

echo
echo "=== read -r -a (em array) ==="
read -r -a palavras -p "Digite várias palavras: "
echo "Palavras: ${palavras[*]}"
echo "Quantidade: ${#palavras[@]}"