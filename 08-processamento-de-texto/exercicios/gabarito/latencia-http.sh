#!/usr/bin/env bash
#
# latencia-http.sh - monitor de latência HTTP com estatísticas.
#
# Uso: ./latencia-http.sh URL [NUM_REQUISICOES]

set -Eeuo pipefail

[[ $# -ge 1 ]] || { echo "Uso: $0 URL [NUM_REQUISICOES]" >&2; exit 2; }

URL="$1"
N="${2:-10}"

command -v curl >/dev/null || { echo "ERRO: curl não instalado" >&2; exit 3; }

echo "=== Teste de Latência HTTP ==="
echo "URL: $URL"
echo "Requisições: $N"
echo

# Array para armazenar tempos
declare -a tempos

for i in $(seq 1 "$N"); do
    # curl -w: time_connect, time_starttransfer, time_total (em segundos)
    # -s silencioso, -o descarta body, -f falha em HTTP >= 400
    resultado=$(curl -f -s -o /dev/null -w "connect=%{time_connect} starttransfer=%{time_starttransfer} total=%{time_total} http=%{http_code}" --max-time 10 "$URL" 2>&1)
    codigo=$?

    if (( codigo == 0 )); then
        total=$(echo "$resultado" | grep -o 'total=[0-9.]*' | cut -d= -f2)
        http=$(echo "$resultado" | grep -o 'http=[0-9]*' | cut -d= -f2)

        if (( http >= 200 && http < 300 )); then
            ms=$(awk -v t="$total" 'BEGIN {printf "%.0f", t*1000}')
            tempos+=("$ms")
            printf "[%02d] HTTP %d  %4dms  connect=%s  starttransfer=%s\n" \
                "$i" "$http" "$ms" \
                "$(echo "$resultado" | grep -o 'connect=[0-9.]*' | cut -d= -f2)" \
                "$(echo "$resultado" | grep -o 'starttransfer=[0-9.]*' | cut -d= -f2)"
        else
            echo "[$i] HTTP $http - não conta como sucesso"
        fi
    else
        echo "[$i] FALHA: $resultado"
    fi

    sleep 0.5  # pequeno delay entre requisições
done

if (( ${#tempos[@]} == 0 )); then
    echo "Nenhuma requisição bem-sucedida."
    exit 1
fi

# Estatísticas
IFS=$'\n' sorted=($(sort -n <<<"${tempos[*]}"))
count=${#sorted[@]}
min=${sorted[0]}
max=${sorted[-1]}
soma=$(IFS=+; echo "$((${sorted[*]}))")
media=$(( soma / count ))
p95_idx=$(( count * 95 / 100 ))
(( p95_idx >= count )) && p95_idx=$((count-1))
p95=${sorted[p95_idx]}

echo
echo "=== Estatísticas (${count} amostras bem-sucedidas) ==="
printf "Mínimo:    %4d ms\n" "$min"
printf "Máximo:    %4d ms\n" "$max"
printf "Média:     %4d ms\n" "$media"
printf "P95:       %4d ms\n" "$p95"

# Histograma simples
echo
echo "Distribuição:"
for bucket in 0 50 100 200 300 500 1000; do
    next_bucket=$(( bucket + 50 ))
    if (( bucket == 1000 )); then
        next_bucket=9999
    fi
    count_bucket=0
    for t in "${tempos[@]}"; do
        (( t >= bucket && t < next_bucket )) && (( count_bucket++ ))
    done
    if (( count_bucket > 0 )); then
        bar=$(printf '█%.0s' $(seq 1 $(( count_bucket * 20 / count ))))
        printf "%4d-%4dms: %2d %s\n" "$bucket" "$((next_bucket-1))" "$count_bucket" "$bar"
    fi
done