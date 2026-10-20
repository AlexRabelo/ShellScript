#!/usr/bin/env bash
#
# confirma-senha.sh - pede senha e confirmação, compara sem exibir.
#
# Uso: ./confirma-senha.sh

read -sp "Senha: " senha1
echo
read -sp "Confirme a senha: " senha2
echo

if [[ "$senha1" == "$senha2" ]]; then
    echo "Senhas conferem"
    exit 0
else
    echo "Senhas diferentes"
    exit 1
fi