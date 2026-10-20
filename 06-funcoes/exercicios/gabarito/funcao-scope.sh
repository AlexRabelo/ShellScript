#!/usr/bin/env bash
# funcao-scope.sh — Gabarito Exercício 3

total=0

adiciona() {
    local total=0
    total=$(( total + $1 ))
    echo "Local: $total"
}

adiciona 10
adiciona 20
echo "Global: $total"