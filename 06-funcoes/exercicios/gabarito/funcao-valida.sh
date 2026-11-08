#!/usr/bin/env bash
# funcao-valida.sh — Gabarito Exercício 1

saudacao() {
    local nome="$1"
    [[ -z "$nome" ]] && { echo "Erro: nome obrigatório" >&2; return 2; }
    echo "Olá, $nome!"
    return 0
}

saudacao ""
saudacao "Ana"