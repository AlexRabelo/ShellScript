#!/usr/bin/env bash
# teste-string.sh — Gabarito Exercício 1

nome=""
servico="nginx"

[[ -z "$nome" ]] && echo "nome vazio"
[[ -n "$servico" ]] && echo "servico definido"
[[ "$servico" == *gin* ]] && echo "contém 'gin' (glob)"
[[ "$servico" =~ ^ng.*x$ ]] && echo "casa com regex ^ng.*x$"