#!/usr/bin/env bash
#
# soma-media.sh - recebe dois números e imprime soma, produto e médias.
#
# Uso: ./soma-media.sh NUM1 NUM2

[[ $# -eq 2 ]] || { echo "Uso: $0 NUM1 NUM2" >&2; exit 2; }

a="$1"
b="$2"

# Valida números inteiros (permite negativo)
[[ "$a" =~ ^-?[0-9]+$ ]] || { echo "Erro: '$a' não é um número inteiro" >&2; exit 1; }
[[ "$b" =~ ^-?[0-9]+$ ]] || { echo "Erro: '$b' não é um número inteiro" >&2; exit 1; }

soma=$(( a + b ))
produto=$(( a * b ))
media_int=$(( soma / 2 ))

# Média com uma casa decimal usando awk (mais portável que bc)
media_dec=$(awk "BEGIN { printf \"%.1f\", ($a + $b) / 2 }")

echo "Números: $a e $b"
echo "Soma:       $soma"
echo "Produto:    $produto"
echo "Média int:  $media_int"
echo "Média dec:  $media_dec"