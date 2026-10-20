#!/usr/bin/env bash
#
# deploy-hosts.sh - executa comando em múltiplos hosts via SSH.
#
# Uso: ./deploy-hosts.sh ARQUIVO_HOSTS "COMANDO"
#   ARQUIVO_HOSTS: um host por linha (IP ou hostname)
#   COMANDO: comando a executar remotamente

[[ $# -eq 2 ]] || { echo "Uso: $0 ARQUIVO_HOSTS \"COMANDO\"" >&2; exit 2; }

arquivo="$1"
comando="$2"

[[ -f "$arquivo" ]] || { echo "ERRO: Arquivo '$arquivo' não existe" >&2; exit 1; }

echo "=== Deploy Paralelo via SSH ==="
echo "Hosts: $(wc -l < "$arquivo")"
echo "Comando: $comando"
echo

sucessos=0
falhas=0

while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    [[ "$host" =~ ^#.* ]] && continue  # pula comentários

    printf "%-20s ... " "$host"

    # SSH com timeout de conexão, BatchMode (sem senha), StrictHostKeyChecking=no
    saida=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$host" "$comando" 2>&1)
    codigo=$?

    if (( codigo == 0 )); then
        echo "SUCESSO"
        (( sucessos++ ))
    else
        echo "FALHA (exit $codigo)"
        echo "  $saida" | head -3 | sed 's/^/  /'
        (( falhas++ ))
    fi
done < "$arquivo"

echo
echo "=== Resumo ==="
echo "Sucessos: $sucessos"
echo "Falhas:   $falhas"

[[ $falhas -eq 0 ]] && exit 0 || exit 1