#!/usr/bin/env bash
# expansao.sh — Gabarito Exercício 1

app="nginx"
porta=80
versao=""

echo "App: $app, Porta: $porta, Versão: ${versao:-1.24} (default)"
# versao continua vazia
echo "versao depois: '${versao}'"