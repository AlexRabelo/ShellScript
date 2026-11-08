#!/usr/bin/env bash
#
# monitor-servico.sh - verifica status de serviço systemd.
#
# Uso: ./monitor-servico.sh NOME_DO_SERVICO

[[ $# -eq 1 ]] || { echo "Uso: $0 SERVICO" >&2; exit 2; }

servico="$1"

# Verifica se o serviço existe
if ! systemctl list-unit-files --no-legend "$servico" 2>/dev/null | grep -q "^$servico"; then
    # Verifica também sem extensão .service
    if ! systemctl list-unit-files --no-legend "${servico}.service" 2>/dev/null | grep -q "^${servico}.service"; then
        echo "SERVIÇO NÃO EXISTE: $servico" >&2
        exit 2
    fi
    servico="${servico}.service"
fi

estado=$(systemctl is-active "$servico" 2>/dev/null)
codigo=$?

case "$estado" in
    active)
        echo "SERVIÇO ATIVO: $servico"
        exit 0
        ;;
    inactive|failed)
        echo "SERVIÇO PARADO: $servico (estado: $estado)"
        exit 1
        ;;
    *)
        echo "ESTADO DESCONHECIDO: $servico ($estado)" >&2
        exit 3
        ;;
esac