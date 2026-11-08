#!/usr/bin/env bash
# funcao-shift.sh — Gabarito Exercício 4

prefixa_linhas() {
    local prefixo="$1"
    shift
    for linha in "$@"; do
        echo "$prefixo: $linha"
    done
}

prefixa_linhas "LOG" "iniciando" "processando item 1" "processando item 2" "finalizando" "fim"