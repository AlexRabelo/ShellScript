#!/usr/bin/env bash
#
# conta-erros.sh - conta linhas com ERROR/ERRO em arquivo de log.
#
# Uso: ./conta-erros.sh ARQUIVO_LOG

[[ $# -eq 1 ]] || { echo "Uso: $0 ARQUIVO_LOG" >&2; exit 2; }

arquivo="$1"
[[ -f "$arquivo" ]] || { echo "ERRO: Arquivo '$arquivo' não existe" >&2; exit 1; }
[[ -r "$arquivo" ]] || { echo "ERRO: Arquivo '$arquivo' sem permissão de leitura" >&2; exit 1; }

contador=0

while IFS= read -r linha; do
    # Converte para maiúscula e testa
    if [[ "${linha^^}" == *ERROR* || "${linha^^}" == *ERRO* ]]; then
        (( contador++ ))
    fi
done < "$arquivo"

echo "Total de linhas com ERROR/ERRO: $contador"