#!/usr/bin/env bash
# conceito-parametros.sh — Parâmetros posicionais e especiais (versão didática)

echo "=== Parâmetros recebidos ==="
echo "Script: $0"
echo "Quantidade (\$#): $#"
echo "Todos (\$*): $*"
echo "PID (\$\$): $$"

echo
echo "=== Iteração correta com \"\$@\" ==="
i=1
for arg in "$@"; do
    echo "  \$${i} = [$arg]"
    ((i++))
done

echo
echo "=== Shift — consome argumentos ==="
echo "Antes do shift: \$1=$1, \$2=$2, \$#=$#"
shift
echo "Depois de 1 shift: \$1=$1, \$#=$#"
shift 2
echo "Depois de shift 2: \$1=$1, \$#=$#"

echo
echo "=== Parâmetros especiais úteis ==="
true  # comando que sempre retorna 0
echo "Último código de saída (\$?): $?"
echo "Último PID background (\$!): $!"