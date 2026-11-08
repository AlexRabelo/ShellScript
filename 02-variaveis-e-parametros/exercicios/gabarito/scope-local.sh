#!/usr/bin/env bash
# scope-local.sh — Gabarito Exercício 6

contador=100

incrementa() {
    local contador=0
    for i in {1..3}; do
        ((contador++))
    done
    echo "Local final: $contador"
}

incrementa
echo "Global: $contador"