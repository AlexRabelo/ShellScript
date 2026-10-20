#!/usr/bin/env bash
# menu-servico.sh — Gabarito Exercício 2

[[ $# -ge 1 ]] || { echo "Uso: $0 {start|stop|restart|status|enable|disable}" >&2; exit 2; }

acao="$1"

case "$acao" in
    start|enable)
        echo "Ativando serviço..."
        ;;
    stop|disable)
        echo "Desativando serviço..."
        ;;
    restart)
        echo "Reiniciando serviço..."
        ;;
    status)
        echo "Verificando status..."
        ;;
    *)
        echo "Ação inválida: '$acao'" >&2
        echo "Uso: $0 {start|stop|restart|status|enable|disable}" >&2
        exit 2
        ;;
esac