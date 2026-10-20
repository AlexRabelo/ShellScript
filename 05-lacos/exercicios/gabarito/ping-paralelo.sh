#!/usr/bin/env bash
#
# ping-paralelo.sh - testa conectividade em paralelo com xargs.
#
# Uso: ./ping-paralelo.sh ARQUIVO_HOSTS

[[ $# -eq 1 ]] || { echo "Uso: $0 ARQUIVO_HOSTS" >&2; exit 2; }

arquivo="$1"
[[ -f "$arquivo" ]] || { echo "ERRO: Arquivo '$arquivo' não existe" >&2; exit 1; }

echo "=== Ping Paralelo (xargs -P 10) ==="
echo "Hosts: $(wc -l < "$arquivo")"
echo

inicio=$(date +%s)

# xargs -P 10 roda até 10 processos em paralelo
# -I {} substitui {} pelo host
# Saída: host responde -> imprime host
cat "$arquivo" | xargs -P 10 -I {} bash -c 'ping -c 1 -W 1 "{}" >/dev/null 2>&1 && echo "{}"'

fim=$(date +%s)
tempo_paralelo=$(( fim - inicio ))

echo
echo "Tempo paralelo: ${tempo_paralelo}s"
echo
echo "=== Comparação: Sequencial ==="

inicio=$(date +%s)
while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    ping -c 1 -W 1 "$host" >/dev/null 2>&1 && echo "$host"
done < "$arquivo"
fim=$(date +%s)
tempo_sequencial=$(( fim - inicio ))

echo "Tempo sequencial: ${tempo_sequencial}s"
echo
echo "Speedup: ~$(( tempo_sequencial * 100 / tempo_paralelo ))%"