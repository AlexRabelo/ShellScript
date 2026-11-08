#!/usr/bin/env bash
# array-associativo.sh — Gabarito Exercício 4

declare -A ips=( ["producao"]="10.0.1.10" ["homolog"]="10.0.2.20" )
ips["dev"]="10.0.3.30"

for env in "${!ips[@]}"; do
    echo "Ambiente: $env → IP: ${ips[$env]}"
done

echo "IP de homolog: ${ips[homolog]}"