#!/usr/bin/env bash
#
# conexoes.sh - relatório de conexões de rede formatado.
#
# Uso: ./conexoes.sh [LISTEN|ESTABLISHED|ALL]

set -Eeuo pipefail

FILTRO="${1:-LISTEN}"

# Usa ss (moderno) ou netstat (legacy)
if command -v ss >/dev/null 2>&1; then
    # ss -tunap: tcp, udp, numeric, all, processes
    # Filtra estado
    case "$FILTRO" in
        LISTEN)     ss -tunlp ;;
        ESTABLISHED) ss -tunap state established ;;
        ALL)        ss -tunap ;;
        *)          echo "Filtro inválido: $FILTRO (use LISTEN, ESTABLISHED, ALL)" >&2; exit 2 ;;
    esac
else
    netstat -tunap
fi | \
awk '
    NR==1 { next }  # pula cabeçalho
    {
        proto=$1
        local_addr=$5
        foreign_addr=$6
        state=$2
        pid_proc=$7

        # Extrai IP e porta do endereço local
        if (match(local_addr, /([^:]+):([0-9]+)$/, m)) {
            ip=m[1]; port=m[2]
        } else {
            ip=local_addr; port=""
        }

        # Extrai PID e nome do processo
        if (match(pid_proc, /pid=([0-9]+),.*comm=([^,]+)/, m)) {
            pid=m[1]; proc=m[2]
        } else if (match(pid_proc, /([0-9]+)\/([^ ]+)/, m)) {
            pid=m[1]; proc=m[2]
        } else {
            pid="-"; proc=pid_proc
        }

        # Filtra por estado se necessário
        if ("'"$FILTRO"'" == "ALL" || state == "'"$FILTRO"'") {
            printf "%-6s %-15s %-6s %-12s %s/%s\n", proto, ip, port, state, pid, proc
        }
    }
' | column -t