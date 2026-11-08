#!/usr/bin/env bash
#
# classifica.sh - classifica um número em várias categorias.
#
# Uso: ./classifica.sh NUMERO

[[ $# -eq 1 ]] || { echo "Uso: $0 NUMERO" >&2; exit 2; }

num="$1"

# Valida inteiro
[[ "$num" =~ ^-?[0-9]+$ ]] || { echo "Erro: '$num' não é inteiro" >&2; exit 1; }

echo "Número: $num"
echo

# Positivo, Negativo ou Zero
if (( num > 0 )); then
    echo "Sinal: Positivo"
elif (( num < 0 )); then
    echo "Sinal: Negativo"
else
    echo "Sinal: Zero"
fi

# Par ou Ímpar
if (( num % 2 == 0 )); then
    echo "Paridade: Par"
else
    echo "Paridade: Ímpar"
fi

# Pequeno, Médio, Grande
if (( num >= 0 && num <= 10 )); then
    echo "Magnitude: Pequeno (0-10)"
elif (( num >= 11 && num <= 100 )); then
    echo "Magnitude: Médio (11-100)"
else
    echo "Magnitude: Grande (>100)"
fi