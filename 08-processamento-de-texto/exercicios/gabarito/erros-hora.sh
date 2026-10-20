#!/usr/bin/env bash
#
# erros-hora.sh - agrupa erros por hora com gráfico ASCII.
#
# Uso: ./erros-hora.sh [ARQUIVO_LOG]

set -Eeuo pipefail

ARQUIVO="${1:-/var/log/app.log}"

[[ -f "$ARQUIVO" ]] || { echo "ERRO: Arquivo '$ARQUIVO' não existe" >&2; exit 1; }

# Declara array associativo para contagem por hora
declare -A contagem

# Parse do timestamp ISO: 2026-10-12T14:30:45.123Z
while IFS= read -r linha; do
    # Extrai hora do formato ISO (posição T+1 até T+2)
    if [[ "$linha" =~ T([0-9]{2}): ]]; then
        hora="${BASH_REMATCH[1]}"
        # Filtra apenas linhas de erro
        if [[ "${linha^^}" == *ERROR* || "${linha^^}" == *ERRO* || "${linha^^}" == *FATAL* || "${linha^^}" == *EXCEPTION* ]]; then
            (( contagem["$hora"]++ ))
        fi
    fi
done < "$ARQUIVO"

echo "=== Erros por Hora ==="
echo

# Encontra máximo para normalizar gráfico
max=0
for h in "${!contagem[@]}"; do
    (( contagem[h] > max )) && max=${contagem[h]}
done

# Imprime ordenado por hora
for h in $(printf '%s\n' "${!contagem[@]}" | sort -n); do
    count=${contagem[$h]}
    # Gráfico proporcional (máx 40 chars)
    if (( max > 0 )); then
        barras=$(( count * 40 / max ))
    else
        barras=0
    fi
    grafico=$(printf '█%.0s' $(seq 1 $barras))
    printf "%02d:00  |  %4d  |  %s\n" "$h" "$count" "$grafico"
done