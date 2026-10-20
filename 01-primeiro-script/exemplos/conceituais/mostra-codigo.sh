#!/usr/bin/env bash
#
# mostra-codigo.sh - Demonstra códigos de saída (exit) e $?
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   mostra-codigo.sh
#
# Demonstra:
#   - exit 0  → sucesso
#   - exit 1  → falha genérica
#   - $?      → variável especial com código do último comando
#
# =============================================================================

echo "=== Demonstração de códigos de saída ==="
echo

echo "1. Comando que succeeds (ls /etc):"
ls /etc > /dev/null
echo "   Código de saída (\$?): $?"

echo
echo "2. Comando que falha (ls /nao-existe):"
ls /nao-existe > /dev/null 2>&1
echo "   Código de saída (\$?): $?"

echo
echo "3. Script filho com exit 0 (sucesso):"
bash -c 'exit 0'
echo "   Código de saída (\$?): $?"

echo
echo "4. Script filho com exit 1 (falha):"
bash -c 'exit 1'
echo "   Código de saída (\$?): $?"

echo
echo "5. Script filho com exit 2 (uso incorreto):"
bash -c 'exit 2'
echo "   Código de saída (\$?): $?"

echo
echo "=== Fim da demonstração ==="
exit 0