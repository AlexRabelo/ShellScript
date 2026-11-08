#!/usr/bin/env bash
#
# monitora-processo.sh - monitora contagem de instâncias de um processo.
#
# Uso: ./monitora-processo.sh NOME_PROCESSO [INTERVALO_SEGUNDOS]

[[ $# -ge 1 ]] || { echo "Uso: $0 NOME_PROCESSO [INTERVALO]" >&2; exit 2; }

processo="$1"
intervalo="${2:-5}"

# Trap para sair graciosamente
trap 'echo; echo "Monitoramento interrompido."; exit 0' INT

echo "Monitorando '$processo' a cada ${intervalo}s (Ctrl+C para sair)"
echo

while true; do
    count=$(pgrep -c "$processo" 2>/dev/null || echo 0)

    if (( count == 0 )); then
        echo -e "$(date '+%H:%M:%S') ALERTA: Nenhuma instância de '$processo' rodando! \a"
    else
        echo "$(date '+%H:%M:%S') OK: $count instância(s) de '$processo'"
    fi

    sleep "$intervalo"
done