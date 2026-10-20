#!/usr/bin/env bash
#
# checa-comandos.sh - verifica se comandos existem.
#
# Uso: ./checa-comandos.sh CMD1 [CMD2...]

[[ $# -ge 1 ]] || { echo "Uso: $0 CMD1 [CMD2...]" >&2; exit 2; }

encontrados=0
faltando=0

for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd: OK"
        (( encontrados++ ))
    else
        echo "$cmd: NÃO ENCONTRADO"
        (( faltando++ ))
    fi
done

echo
echo "Total: $encontrados encontrados, $faltando faltando"

[[ $faltando -eq 0 ]] && exit 0 || exit 1