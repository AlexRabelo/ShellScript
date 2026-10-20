#!/usr/bin/env bash
# conceito-case.sh — case com glob patterns (versão didática)

acao="${1:-status}"

echo "=== case básico ==="
case "$acao" in
    start)
        echo "Ação: INICIAR"
        ;;
    stop)
        echo "Ação: PARAR"
        ;;
    restart)
        echo "Ação: REINICIAR"
        ;;
    status)
        echo "Ação: STATUS"
        ;;
    *)
        echo "Ação desconhecida: '$acao'"
        echo "Use: start|stop|restart|status"
        ;;
esac

echo
echo "=== case com alternância (|) ==="
nivel="${2:-info}"
case "$nivel" in
    debug|verbose)
        echo "Nível: VERBOSE ($nivel)"
        ;;
    info|warning)
        echo "Nível: NORMAL ($nivel)"
        ;;
    error|critical|fatal)
        echo "Nível: CRÍTICO ($nivel)"
        ;;
    *)
        echo "Nível desconhecido: '$nivel'"
        ;;
esac

echo
echo "=== case com glob pattern ==="
arquivo="${3:-teste.txt}"
case "$arquivo" in
    *.log)
        echo "Arquivo de LOG"
        ;;
    *.conf|*.config)
        echo "Arquivo de CONFIG"
        ;;
    *.sh)
        echo "Script SHELL"
        ;;
    *)
        echo "Tipo desconhecido: $arquivo"
        ;;
esac