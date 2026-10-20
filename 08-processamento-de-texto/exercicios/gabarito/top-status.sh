#!/usr/bin/env bash
#
# top-status.sh - top códigos HTTP em access.log.
#
# Uso: ./top-status.sh [ARQUIVO_LOG] [TOP_N]

set -Eeuo pipefail

ARQUIVO="${1:-/var/log/nginx/access.log}"
TOP_N="${2:-10}"

[[ -f "$ARQUIVO" ]] || { echo "ERRO: Arquivo '$ARQUIVO' não existe" >&2; exit 1; }

echo "=== Top $TOP_N Códigos HTTP ==="
echo "Arquivo: $ARQUIVO"
echo

# Combined log format: $9 = status HTTP
# Usa LC_ALL=C para sort mais rápido (ordem de bytes)
LC_ALL=C awk '{print $9}' "$ARQUIVO" | \
    LC_ALL=C sort | \
    uniq -c | \
    LC_ALL=C sort -rn | \
    head -"$TOP_N" | \
    awk '{printf "%5d  %s\n", $1, $2}'