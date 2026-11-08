#!/usr/bin/env bash
#
# parse-json.sh - parse de JSON com jq (prep para módulo 14).
#
# Uso: ./parse-json.sh ARQUIVO_JSON

set -Eeuo pipefail

[[ $# -eq 1 ]] || { echo "Uso: $0 ARQUIVO_JSON" >&2; exit 2; }

ARQUIVO="$1"
[[ -f "$ARQUIVO" ]] || { echo "ERRO: Arquivo não existe" >&2; exit 1; }

command -v jq >/dev/null || { echo "ERRO: jq não instalado" >&2; exit 3; }

echo "=== Análise de JSON ==="
echo

# Exemplo de estrutura esperada:
# [{"host":"web01","cpu":45,"mem":2048},{"host":"web02","cpu":78,"mem":4096}]

# Conta objetos no array
total=$(jq 'length' "$ARQUIVO")
echo "Total de servidores: $total"

# Média de CPU
media_cpu=$(jq '[.[] | .cpu] | add / length' "$ARQUIVO")
echo "CPU Média: ${media_cpu}%"

# Máximo de CPU
max_cpu=$(jq '[.[] | .cpu] | max' "$ARQUIVO")
echo "CPU Máxima: ${max_cpu}%"

# Host com maior CPU
host_max=$(jq -r 'max_by(.cpu) | .host' "$ARQUIVO")
echo "Host mais carregado: $host_max (${max_cpu}%)"

# Soma de memória (em MB)
total_mem=$(jq '[.[] | .mem] | add' "$ARQUIVO")
echo "Memória Total Alocada: ${total_mem} MB"

# Lista hosts com CPU > 70%
echo
echo "--- Hosts com CPU > 70% ---"
jq -r '.[] | select(.cpu > 70) | "\(.host): \(.cpu)%"' "$ARQUIVO"