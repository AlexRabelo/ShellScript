#!/usr/bin/env bash
# funcao-global.sh — Gabarito Exercício 6

logs=()

loga() {
    logs+=("$(date '+%H:%M:%S') $1")
}

mostra_logs() {
    for entry in "${logs[@]}"; do
        echo "$entry"
    done
}

loga "iniciando"
loga "processando"
loga "fim"
mostra_logs