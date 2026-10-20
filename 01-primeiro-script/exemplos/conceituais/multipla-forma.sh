#!/usr/bin/env bash
#
# multipla-forma.sh - Demonstra três formas de executar um script
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   multipla-forma.sh
#
# Demonstra:
#   1. ./script.sh        → precisa chmod +x, usa shebang
#   2. bash script.sh     → não precisa chmod +x, ignora shebang
#   3. source script.sh   → roda no shell ATUAL (não cria processo filho)
#
# =============================================================================

echo "=== Três formas de executar um script ==="
echo

echo "Este script mostra qual forma foi usada para executá-lo."
echo

# Detecta como foi executado
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Executado como ./script.sh ou bash script.sh
    if [[ -n "${BASH_EXECUTION_STRING}" ]]; then
        echo "Forma detectada: bash script.sh (ou bash -c '...')"
        echo "  - Não precisa de chmod +x"
        echo "  - Shebang é IGNORADO"
        echo "  - Roda em processo FILHO (subshell)"
    else
        echo "Forma detectada: ./script.sh (caminho explícito)"
        echo "  - PRECISA de chmod +x"
        echo "  - Shebang É USADO"
        echo "  - Roda em processo FILHO (subshell)"
    fi
else
    # Executado com source ou .
    echo "Forma detectada: source script.sh (ou . script.sh)"
    echo "  - Não precisa de chmod +x"
    echo "  - Shebang é IGNORADO"
    echo "  - Roda no shell ATUAL (mesmo processo)"
    echo "  - Variáveis criadas AQUI ficam disponíveis DEPOIS"
fi

echo
echo "=== Diferença prática (variáveis) ==="
echo
echo "Tente rodar de cada forma e veja a diferença:"
echo
echo "  $ ./multipla-forma.sh"
echo "  $ bash multipla-forma.sh"
echo "  $ source multipla-forma.sh"
echo "  $ . multipla-forma.sh"
echo
echo "Com 'source' ou '.', a variável abaixo ficará no seu shell:"
MINHA_VARIAVEL="valor_definido_no_script"
echo "MINHA_VARIAVEL='$MINHA_VARIAVEL' (dentro do script)"

exit 0