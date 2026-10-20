#!/usr/bin/env bash
#
# checa-arquivo.sh - verifica se arquivo existe, não vazio e legível.
#
# Uso: ./checa-arquivo.sh CAMINHO
# Códigos de saída:
#   0: OK
#   1: não existe ou não é arquivo regular
#   2: está vazio
#   3: não legível

[[ $# -eq 1 ]] || { echo "Uso: $0 CAMINHO" >&2; exit 2; }

caminho="$1"

if [[ ! -f "$caminho" ]]; then
    echo "Falha: '$caminho' não existe ou não é arquivo regular" >&2
    exit 1
fi

if [[ ! -s "$caminho" ]]; then
    echo "Falha: '$caminho' está vazio" >&2
    exit 2
fi

if [[ ! -r "$caminho" ]]; then
    echo "Falha: '$caminho' não é legível" >&2
    exit 3
fi

echo "OK: $caminho existe, não está vazio e é legível"
exit 0