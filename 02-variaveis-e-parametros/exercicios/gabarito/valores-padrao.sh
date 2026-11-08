#!/usr/bin/env bash
#
# valores-padrao.sh - demonstra valores padrão para argumentos.
#
# Uso: ./valores-padrao.sh [ARQUIVO] [DIRETORIO] [PREFIXO]

arquivo="${1:-dados.txt}"
diretorio="${2:-/tmp}"
prefixo="${3:-bkp}"

echo "Valores que serão usados:"
echo "  Arquivo:   $arquivo"
echo "  Diretório: $diretorio"
echo "  Prefixo:   $prefixo"
echo
echo "Nome do backup seria: ${diretorio}/${prefixo}-${arquivo}"