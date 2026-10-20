#!/usr/bin/env bash
#
# cpu-processo.sh - monitora %CPU de um processo.
#
# Uso: ./cpu-processo.sh PID [INTERVALO] [MAX_AMOSTRAS]

set -Eeuo pipefail

[[ $# -ge 1 ]] || { echo "Uso: $0 PID [INTERVALO] [MAX_AMOSTRAS]" >&2; exit 2; }

PID="$1"
INTERVALO="${2:-2}"
MAX="${3:-20}"

# Valida PID
kill -0 "$PID" 2>/dev/null || { echo "ERRO: Processo $PID não existe" >&2; exit 1; }

echo "Monitorando PID $PID (intervalo: ${INTERVALO}s, max: $MAX amostras)"
echo "Pressione Ctrl+C para parar"
echo

amostras=0
max_cpu=0
soma_cpu=0

while (( amostras < MAX )); do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "Processo $PID terminou."
        break
    fi

    # Lê %CPU do ps (ajusta formato)
    cpu=$(ps -p "$PID" -o %cpu= 2>/dev/null | xargs)
    cmd=$(ps -p "$PID" -o cmd= 2>/dev/null | cut -c1-50)

    # Atualiza estatísticas
    if [[ -n "$cpu" ]]; then
        (( amostras++ ))
        # Comparação float via awk
        max_cpu=$(awk -v a="$max_cpu" -v b="$cpu" 'BEGIN {print (a>b)?a:b}')
        soma_cpu=$(awk -v a="$soma_cpu" -v b="$cpu" 'BEGIN {print a+b}')

        # Gráfico de barras (máx 50 chars)
        barras=$(awk -v c="$cpu" 'BEGIN {print int(c/2)}')
        (( barras > 50 )) && barras=50
        grafico=$(printf '█%.0s' $(seq 1 $barras))

        printf "[%02d] CPU: %5.1f%%  %s  %s\n" "$amostras" "$cpu" "$grafico" "$cmd"
    fi

    sleep "$INTERVALO"
done

if (( amostras > 0 )); then
    media=$(awk -v s="$soma_cpu" -v n="$amostras" 'BEGIN {printf "%.1f", s/n}')
    echo
    echo "=== Resumo ==="
    echo "Amostras: $amostras"
    echo "Média:    ${media}%"
    echo "Pico:     ${max_cpu}%"
fi