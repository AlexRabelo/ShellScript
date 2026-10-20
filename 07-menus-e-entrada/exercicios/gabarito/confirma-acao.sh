#!/usr/bin/env bash
#
# confirma-acao.sh - prompt de confirmação seguro [s/N].
#
# Uso: ./confirma-acao.sh "Mensagem de confirmação"
#      ./confirma-acao.sh "Mensagem" && echo "Confirmado" || echo "Cancelado"

set -Eeuo pipefail

MENSAGEM="${1:-Confirma a operação?}"

# Se não for terminal interativo, assume NÃO (seguro para cron/CI)
if [[ ! -t 0 ]]; then
    echo "Não-interativo: assumindo NÃO por segurança" >&2
    exit 1
fi

read -rp "${MENSAGEM} [s/N] " resposta

# Converte para minúscula e remove espaços
resposta="${resposta,,}"
resposta="${resposta// /}"

case "$resposta" in
    s|sim|y|yes)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac