#!/usr/bin/env bash
#
# lista-args.sh - mostra informações sobre os argumentos recebidos.
#
# Uso: ./lista-args.sh [ARGUMENTOS...]

echo "=== Informações dos argumentos ==="
echo "Nome do script (\$0): $0"
echo "Quantidade (\$#): $#"
echo

echo "--- Argumentos individuais ---"
i=1
for arg in "$@"; do
    echo "  \$${i}: [$arg]"
    (( i++ ))
done

echo
echo "--- Diferença entre \"\$@\" e \$* ---"
echo "Com \"\$@\" (cada argumento preservado):"
for arg in "$@"; do
    echo "  [$arg]"
done

echo "Com \$* (tudo junto, separado por IFS):"
for arg in $*; do
    echo "  [$arg]"
done