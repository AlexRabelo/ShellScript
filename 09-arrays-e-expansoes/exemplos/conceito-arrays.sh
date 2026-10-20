#!/usr/bin/env bash
# conceito-arrays.sh — Arrays indexados e associativos (versão didática)

echo "=== Array indexado com buracos ==="
arr=(a b c d e)
unset 'arr[2]'           # remove índice 2
arr[10]=z              # índice esparso

echo "Elementos: ${arr[*]}"
echo "Índices:   ${!arr[*]}"
echo "Quantidade: ${#arr[@]}"

echo
echo "Iteração segura (respeita buracos):"
for i in "${!arr[@]}"; do
    echo "  [$i] = ${arr[i]}"
done

echo
echo "=== Array associativo ==="
declare -A servicos=( ["web"]="nginx" ["db"]="postgres" ["cache"]="redis" )
servicos["queue"]="rabbitmq"
unset 'servicos[db]'

for s in "${!servicos[@]}"; do
    echo "  $s -> ${servicos[$s]}"
done

echo
echo "=== Inspeção com declare -p ==="
declare -p arr
declare -p servicos