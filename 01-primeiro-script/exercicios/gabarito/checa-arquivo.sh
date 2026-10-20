#!/usr/bin/env bash
#
# checa-arquivo.sh - verifica se /etc/passwd existe e repassa o código de saída.

ls /etc/passwd > /dev/null 2>&1
echo "Código de saída: $?"
# O $? precisa ser guardado se for usado depois: o echo acima também gera um
# código. Como ainda não vimos variáveis, repetimos o teste na linha do exit.
ls /etc/passwd > /dev/null 2>&1
exit $?
