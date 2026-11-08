#!/usr/bin/env bash
#
# verifica-dir.sh - verifica se um caminho é diretório gravável.
#
# Uso: ./verifica-dir.sh CAMINHO

[[ $# -eq 1 ]] || { echo "Uso: $0 CAMINHO" >&2; exit 2; }

caminho="$1"
ok=0

echo "Verificando: $caminho"

if [[ -e "$caminho" ]]; then
    echo "  Existe: SIM"
else
    echo "  Existe: NÃO"
    ok=1
fi

if [[ -d "$caminho" ]]; then
    echo "  É diretório: SIM"
else
    echo "  É diretório: NÃO"
    ok=1
fi

if [[ -w "$caminho" ]]; then
    echo "  É gravável: SIM"
else
    echo "  É gravável: NÃO"
    ok=1
fi

if [[ $ok -eq 0 ]]; then
    echo "Resultado: OK"
    exit 0
else
    echo "Resultado: FALHA"
    exit 1
fi