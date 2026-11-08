#!/usr/bin/env bash
#
# case-padrao.sh - classifica log level usando case com padrões.
#
# Uso: ./case-padrao.sh STRING

[[ $# -eq 1 ]] || { echo "Uso: $0 STRING" >&2; exit 2; }

entrada="$1"

case "$entrada" in
    erro*|ERRO*|Error*|error*)
        nivel="CRÍTICO"
        ;;
    aviso*|AVISO*|Warning*|warning*|warn*)
        nivel="ATENÇÃO"
        ;;
    info*|INFO*|Info*)
        nivel="INFORMATIVO"
        ;;
    *)
        nivel="DESCONHECIDO"
        ;;
esac

echo "Entrada: $entrada"
echo "Nível: $nivel"