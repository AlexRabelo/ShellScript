#!/usr/bin/env bash
#
# retry-http.sh - testa endpoint HTTP com retry e backoff.
#
# Uso: ./retry-http.sh URL [MAX_TENTATIVAS] [INTERVALO]

[[ $# -ge 1 ]] || { echo "Uso: $0 URL [MAX_TENTATIVAS] [INTERVALO]" >&2; exit 2; }

url="$1"
max_tentativas="${2:-5}"
intervalo="${3:-2}"

command -v curl >/dev/null || { echo "ERRO: curl não instalado" >&2; exit 3; }

echo "Testando $url (máx $max_tentativas tentativas, intervalo ${intervalo}s)"
echo

tentativa=0
while (( tentativa < max_tentativas )); do
    (( tentativa++ ))
    echo -n "Tentativa $tentativa/$max_tentativas: "

    # curl: -f falha em HTTP >= 400, -s silencioso, -S mostra erros, -o descarta body
    # -w imprime código HTTP e tempo total
    saida=$(curl -f -s -S -o /dev/null -w "HTTP=%{http_code} TIME=%{time_total}s" --max-time 10 "$url" 2>&1)
    codigo=$?

    if (( codigo == 0 )); then
        # Extrai código HTTP
        http_code=$(echo "$saida" | grep -o 'HTTP=[0-9]*' | cut -d= -f2)
        if (( http_code >= 200 && http_code < 300 )); then
            echo "SUCESSO ($saida)"
            exit 0
        else
            echo "FALHA - $saida"
        fi
    else
        echo "FALHA - curl exit $codigo"
    fi

    if (( tentativa < max_tentativas )); then
        echo "  Aguardando ${intervalo}s..."
        sleep "$intervalo"
    fi
done

echo "Todas as $max_tentativas tentativas falharam." >&2
exit 1