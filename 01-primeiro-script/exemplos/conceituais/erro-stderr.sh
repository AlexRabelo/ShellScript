#!/usr/bin/env bash
#
# erro-stderr.sh - Demonstra redirecionamento de erro para stderr (>&2)
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   erro-stderr.sh
#
# Demonstra:
#   - echo "msg"       → vai para stdout (canal 1)
#   - echo "msg" >&2   → vai para stderr (canal 2)
#   - exit 1          → código de falha
#
echo "=== Demonstração: stdout vs stderr ==="
echo

echo "1. Comando que succeeds (stdout):"
ls /etc > /dev/null
codigo=$?
echo "   ls /etc > /dev/null"
echo "   Código de saída: $codigo"

echo
echo "2. Comando que falha (stderr) com >&2:"
ls /nao-existe > /dev/null 2>&1
codigo=$?
echo "   ls /nao-existe > /dev/null 2>&1"
echo "   Código de saída: $codigo"

echo
echo "3. Separando stdout e stderr na execução:"
echo "   Rode assim para ver a separação:"
echo "     ./erro-stderr.sh 2> erros.txt"
echo "   - Mensagem normal (stdout) aparece na tela"
echo "   - Mensagens de erro (stderr) vão para erros.txt"

echo
echo "4. Script que falha com mensagem em stderr (simulado):"
# Simula um script que valida algo e falha
arquivo="/etc/arquivo-que-nao-existe"
if [[ ! -f "$arquivo" ]]; then
    echo "ERRO: Arquivo não encontrado: $arquivo" >&2
    echo "DICA: Verifique o caminho e tente novamente" >&2
    exit 1
fi

echo
exit 0