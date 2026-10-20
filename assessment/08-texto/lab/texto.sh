#!/usr/bin/env bash
# Lab: Módulo 08 — Processamento de Texto
# Tempo: 20 min | Objetivo: Pipeline grep|sed|awk para relatório de access.log

# =============================================================================
# ENUNCIADO
# =============================================================================
# Crie `relatorio-access.sh` que recebe um access.log (formato combined) e imprime:
# 1. Total de requisições
# 2. Top 5 IPs por contagem
# 3. Top 5 IPs por bytes transferidos (soma)
# 4. Códigos de resposta e contagem (ordenado por código)
# 5. Requisições por hora (extraí do timestamp [15/Jan/2024:10:00:01])
# 6. Flags: -h (help), -j (JSON output)
# 7. Passa shellcheck

# =============================================================================
# TEMPLATE BASE (complete as funções)
# =============================================================================

set -Eeuo pipefail

ARQUIVO=""
JSON_OUTPUT=0

usage() {
    cat <<'EOF'
relatorio-access - Relatório de access.log

Uso: relatorio-access.sh [-j] ARQUIVO

Opções:
  -j            Saída JSON
  -h            Ajuda

Exemplos:
  relatorio-access.sh /var/log/nginx/access.log
  relatorio-access.sh -j access.log | jq .
EOF
}

# Total de linhas (requisições)
total_requisicoes() {
    awk 'END {print NR}' "$ARQUIVO"
}

# Top 5 IPs por contagem (campo $1)
top_ips_contagem() {
    awk '{print $1}' "$ARQUIVO" | sort | uniq -c | sort -nr | head -5
}

# Top 5 IPs por bytes (campo $10, soma por IP)
top_ips_bytes() {
    awk '{bytes[$1]+=$10} END {for (ip in bytes) print bytes[ip], ip}' "$ARQUIVO" \
        | sort -nr | head -5
}

# Códigos de resposta (campo $9)
codigos_resposta() {
    awk '{print $9}' "$ARQUIVO" | sort | uniq -c | sort -n
}

# Requisições por hora (extraí hora do campo 4: [15/Jan/2024:10:00:01])
requisicoes_por_hora() {
    awk -F'[[:[]' '{split($2,a,":"); print a[2]}' "$ARQUIVO" | sort | uniq -c | sort -n
}

# Saída JSON consolidada
saida_json() {
    local total ips_contagem ips_bytes codigos horas

    total=$(total_requisicoes)
    ips_contagem=$(top_ips_contagem | awk '{print "{\"ip\":\""$2"\",\"count\":"$1"}"}' | paste -sd,)
    ips_bytes=$(top_ips_bytes | awk '{print "{\"ip\":\""$2"\",\"bytes\":"$1"}"}' | paste -sd,)
    codigos=$(codigos_resposta | awk '{print "{\"code\":\""$2"\",\"count\":"$1"}"}' | paste -sd,)
    horas=$(requisicoes_por_hora | awk '{print "{\"hour\":"$2",\"count\":"$1"}"}' | paste -sd,)

    jq -n \
        --arg arquivo "$ARQUIVO" \
        --arg total "$total" \
        --argjson ips_contagem "[$ips_contagem]" \
        --argjson ips_bytes "[$ips_bytes]" \
        --argjson codigos "[$codigos]" \
        --argjson horas "[$horas]" \
        '{
            arquivo: $arquivo,
            total_requisicoes: ($total | tonumber),
            top_ips_contagem: $ips_contagem,
            top_ips_bytes: $ips_bytes,
            codigos_resposta: $codigos,
            requisicoes_por_hora: $horas
        }'
}

main() {
    local opt
    while getopts "jh" opt; do
        case $opt in
            j) JSON_OUTPUT=1 ;;
            h) usage; exit 0 ;;
            *) usage >&2; exit 2 ;;
        esac
    done
    shift $((OPTIND-1))

    ARQUIVO="${1:-}"

    [[ -z "$ARQUIVO" ]] && { usage >&2; exit 2; }
    [[ ! -r "$ARQUIVO" ]] && { echo "Erro: arquivo '$ARQUIVO' não encontrado ou ilegível" >&2; exit 1; }

    if (( JSON_OUTPUT == 1 )); then
        saida_json
    else
        echo "=== RELATÓRIO DE ACESSO ==="
        echo "Arquivo: $ARQUIVO"
        echo
        echo "Total de requisições: $(total_requisicoes)"
        echo
        echo "--- Top 5 IPs por contagem ---"
        top_ips_contagem
        echo
        echo "--- Top 5 IPs por bytes ---"
        top_ips_bytes
        echo
        echo "--- Códigos de resposta ---"
        codigos_resposta
        echo
        echo "--- Requisições por hora ---"
        requisicoes_por_hora
    fi
}

main "$@"