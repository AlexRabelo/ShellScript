#!/usr/bin/env bash
# array-indexado.sh — Gabarito Exercício 3

hosts=("web01" "web02" "db01")
hosts+=("cache01")

echo "Quantidade: ${#hosts[@]}"
echo "Índices: ${!hosts[*]}"
echo "Todos: ${hosts[*]}"

for h in "${hosts[@]}"; do
    echo "Verificando: $h"
done