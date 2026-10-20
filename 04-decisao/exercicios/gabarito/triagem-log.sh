#!/usr/bin/env bash
#
# triagem-log.sh - classifica uma linha de log por severidade.
#
# Uso: ./triagem-log.sh "LINHA_DE_LOG"

[[ $# -eq 1 ]] || { echo "Uso: $0 \"LINHA_DE_LOG\"" >&2; exit 2; }

linha="$1"

case "${linha^^}" in  # converte para maiúscula para case-insensitive
    *ERROR*|*FATAL*|*CRITICAL*|*CRITICO*|*EXCEPTION*|*PANIC*)
        echo "CRÍTICO"
        ;;
    *WARN*|*WARNING*|*AVISO*|*ALERT*)
        echo "ATENÇÃO"
        ;;
    *INFO*|*DEBUG*|*TRACE*|*NOTICE*)
        echo "INFORMATIVO"
        ;;
    *)
        echo "DESCONHECIDO"
        ;;
esac