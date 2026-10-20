#!/usr/bin/env bash
#
# csv-servidores.sh - processa CSV de servidores com awk.
#
# Uso: ./csv-servidores.sh ARQUIVO_CSV

set -Eeuo pipefail

[[ $# -eq 1 ]] || { echo "Uso: $0 ARQUIVO_CSV" >&2; exit 2; }

ARQUIVO="$1"
[[ -f "$ARQUIVO" ]] || { echo "ERRO: Arquivo não existe" >&2; exit 1; }

echo "=== Análise de Inventário CSV ==="
echo "Arquivo: $ARQUIVO"
echo

# awk com delimitador vírgula
# Pula cabeçalho (NR>1)
# Agrega por ambiente ($3)
awk -F, '
    NR==1 { next }
    {
        gsub(/^[ \t]+|[ \t]+$/, "", $1)  # trim host
        gsub(/^[ \t]+|[ \t]+$/, "", $3)  # trim ambiente
        gsub(/^[ \t]+|[ \t]+$/, "", $4)  # trim cpu
        gsub(/^[ \t]+|[ \t]+$/, "", $5)  # trim mem

        amb=$3
        cpu=$4+0
        mem=$5+0

        count[amb]++
        total_cpu[amb] += cpu
        total_mem[amb] += mem
    }
    END {
        printf "%-15s %10s %12s %12s\n", "AMBIENTE", "SERVIDORES", "CPU_TOTAL", "MEM_TOTAL_GB"
        printf "%-15s %10s %12s %12s\n", "--------", "----------", "---------", "------------"
        for (a in count) {
            printf "%-15s %10d %12d %12.1f\n", a, count[a], total_cpu[a], total_mem[a]/1024
        }
    }
' "$ARQUIVO"