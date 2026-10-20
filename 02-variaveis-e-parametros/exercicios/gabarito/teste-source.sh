#!/usr/bin/env bash
#
# teste-source.sh - demonstra a diferença entre source e execução.
#
# Uso: ./teste-source.sh

echo "=== Testando source ==="
source ./define-var.sh
echo "Após source: minha_var = [$minha_var]"

echo
echo "=== Testando execução normal (bash) ==="
bash ./define-var.sh
echo "Após bash: minha_var = [$minha_var]"

echo
echo "=== Explicação ==="
echo "source (ou .) executa o script NO shell atual -> variáveis persistem"
echo "bash ./script executa em um SUBSHELL -> variáveis morrem ao terminar"