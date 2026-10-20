#!/usr/bin/env bash
#
# falha.sh - escreve um erro no stderr e termina com código 2.
#
# Teste: ./falha.sh > saida.txt
#   -> a mensagem aparece na tela (stderr) e saida.txt fica vazio.

echo "ERRO: configuração ausente" >&2
exit 2
