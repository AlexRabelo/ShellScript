#!/usr/bin/env bash
# calculadora.sh — Gabarito Exercício 4

[[ $# -eq 3 ]] || { echo "Uso: $0 NUM1 OP NUM2" >&2; exit 2; }

n1="$1"
op="$2"
n2="$3"

[[ "$n1" =~ ^-?[0-9]+$ ]] || { echo "Num1 inválido: $n1" >&2; exit 1; }
[[ "$n2" =~ ^-?[0-9]+$ ]] || { echo "Num2 inválido: $n2" >&2; exit 1; }

case "$op" in
    +)  res=$(( n1 + n2 )) ;;
    -)  res=$(( n1 - n2 )) ;;
    \*) res=$(( n1 * n2 )) ;;
    /)
        (( n2 == 0 )) && { echo "Erro: divisão por zero" >&2; exit 1; }
        res=$(( n1 / n2 ))
        ;;
    %)  res=$(( n1 % n2 )) ;;
    \*\*) res=$(( n1 ** n2 )) ;;
    *) echo "Operador inválido: $op (use + - * / % **)" >&2; exit 2 ;;
esac

echo "$n1 $op $n2 = $res"