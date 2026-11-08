#!/usr/bin/env bash
#
# dedup-logs.sh - remove duplicatas preservando ordem original.
#
# Uso: ./dedup-logs.sh ARQUIVO_LOG

set -Eeuo pipefail

[[ $# -eq 1 ]] || { echo "Uso: $0 ARQUIVO_LOG" >&2; exit 2; }

ARQUIVO="$1"
[[ -f "$ARQUIVO" ]] || { echo "ERRO: Arquivo não existe" >&2; exit 1; }

# Conta linhas originais
total_orig=$(wc -l < "$ARQUIVO")

# awk '!seen[$0]++' remove duplicatas preservando ordem
# seen[$0] é 0 na primeira vez (falso -> !0 = verdadeiro -> imprime)
# nas próximas vezes seen[$0] > 0 (verdadeiro -> !verd = falso -> não imprime)
linhas_unicas=$(awk '!seen[$0]++' "$ARQUIVO" | wc -l)

removidas=$(( total_orig - linhas_unicas ))

echo "=== Deduplicação de Log ==="
echo "Linhas originais: $total_orig"
echo "Linhas únicas:    $linhas_unicas"
echo "Removidas:        $removidas"
echo

# Mostra as duplicatas encontradas
echo "--- Duplicatas (apenas as que se repetem) ---"
sort "$ARQUIVO" | uniq -d | head -20