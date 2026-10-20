#!/usr/bin/env bash
# conceito-recursao.sh — Recursão: fatorial e fibonacci (versão didática)

echo "=== Fatorial recursivo ==="
fatorial() {
    local n="$1"
    if (( n <= 1 )); then
        echo 1
    else
        local prev
        prev=$(fatorial $((n - 1)))
        echo $(( n * prev ))
    fi
}

for n in 0 1 2 3 4 5 6; do
    echo "$n! = $(fatorial $n)"
done

echo
echo "=== Fibonacci recursivo (ineficiente mas didático) ==="
fib() {
    local n="$1"
    if (( n <= 1 )); then
        echo $n
    else
        echo $(( $(fib $((n - 1))) + $(fib $((n - 2))) ))
    fi
}

for n in 0 1 2 3 4 5 6 7 8; do
    echo "fib($n) = $(fib $n)"
done

echo
echo "=== Aviso: fib recursivo é exponencial O(2^n) ==="
echo "Para n>30 fica lento. Use iterativo ou memoização em produção."