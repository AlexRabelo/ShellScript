#!/usr/bin/env bash
# conceito-numericos.sh — Comparação numérica (versão didática)

x=10
y=5

echo "=== Preferido: (( )) — sintaxe C ==="
(( x > y )) && echo "x > y"
(( x >= y )) && echo "x >= y"
(( x < y )) || echo "x < y (falso)"
(( x <= y )) || echo "x <= y (falso)"
(( x == y )) || echo "x == y (falso)"
(( x != y )) && echo "x != y"

echo
echo "=== Alternativo: [[ ]] com operadores POSIX ==="
[[ $x -eq $y ]] || echo "-eq: igual (falso)"
[[ $x -ne $y ]] && echo "-ne: diferente"
[[ $x -lt $y ]] || echo "-lt: menor que (falso)"
[[ $x -le $y ]] || echo "-le: menor ou igual (falso)"
[[ $x -gt $y ]] && echo "-gt: maior que"
[[ $x -ge $y ]] && echo "-ge: maior ou igual"

echo
echo "=== Aritmética ==="
(( a = x + y )); echo "a = x + y = $a"
(( a = x - y )); echo "a = x - y = $a"
(( a = x * y )); echo "a = x * y = $a"
(( a = x / y )); echo "a = x / y = $a"
(( a = x % y )); echo "a = x % y = $a"
(( x++ )); echo "x++ = $x"
(( --y )); echo "--y = $y"