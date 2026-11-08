#!/usr/bin/env bash
#
# processa-servidores.sh - processa CSV de servidores e testa conectividade.
#
# Uso: ./processa-servidores.sh ARQUIVO_CSV

[[ $# -eq 1 ]] || { echo "Uso: $0 ARQUIVO_CSV" >&2; exit 2; }

arquivo="$1"
[[ -f "$arquivo" ]] || { echo "ERRO: Arquivo '$arquivo' não existe" >&2; exit 1; }

# Declara arrays associativos para contadores por ambiente
declare -A total_por_amb
declare -A online_por_amb

echo "=== Processamento de Inventário ==="
echo "Arquivo: $arquivo"
echo

# Pula cabeçalho e processa
while IFS=',' read -r nome ip ambiente role; do
    [[ "$nome" == "NOME" ]] && continue  # pula cabeçalho

    # Trim
    nome=$(echo "$nome" | xargs)
    ip=$(echo "$ip" | xargs)
    ambiente=$(echo "$ambiente" | xargs)
    role=$(echo "$role" | xargs)

    # Inicializa contadores se necessário
    [[ -z "${total_por_amb[$ambiente]}" ]] && total_por_amb[$ambiente]=0
    [[ -z "${online_por_amb[$ambiente]}" ]] && online_por_amb[$ambiente]=0

    (( total_por_amb[$ambiente]++ ))

    printf "  %-15s %-15s %-12s ... " "$nome" "$ip" "$ambiente"
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo "ONLINE"
        (( online_por_amb[$ambiente]++ ))
    else
        echo "OFFLINE"
    fi
done < "$arquivo"

echo
echo "=== Resumo por Ambiente ==="
for amb in "${!total_por_amb[@]}"; do
    echo "  $amb: ${online_por_amb[$amb]}/${total_por_amb[$amb]} online"
done