#!/usr/bin/env bash
#
# comandos/logs.sh - Análise de logs (nginx, app, syslog)
#
# Uso: sre-toolkit logs [-j|--json] [-f|--formato TIPO] [-l|--limite N] ARQUIVO_LOG [ARQUIVO_LOG...]
#
# Formatos: nginx, apache, json, syslog, generico

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"
source "${LIB_DIR}/util.sh"

JSON_OUTPUT=0
VERBOSE=0
FORMATO="auto"
LIMITE=10

usage() {
    cat <<EOF
logs - Análise de logs

Uso: sre-toolkit logs [-j|--json] [-f|--formato TIPO] [-l|--limite N] ARQUIVO_LOG [ARQUIVO_LOG...]

Formatos:
  nginx      Logs de acesso nginx
  apache     Logs de acesso apache
  json       Logs JSON lines
  syslog     Logs do sistema
  generico   Texto livre (padrão: auto-detecta)

Opções:
  -j, --json       Saída JSON
  -f, --formato TIPO Formato do log (padrão: auto)
  -l, --limite N   Top N resultados (padrão: 10)
  -h, --help       Exibe ajuda
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -f|--formato) FORMATO="${2:-}"; shift 2 ;;
            -l|--limite) LIMITE="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) break ;;
        esac
    done

    [[ $# -gt 0 ]] || { log_erro "Arquivo de log obrigatório"; usage >&2; exit 2; }

    local arquivos=("$@")

    log_info "início (formato=$FORMATO, limite=$LIMITE, arquivos=${#arquivos[@]})"

    local all_results="[]"

    for arq in "${arquivos[@]}"; do
        [[ -f "$arq" ]] || { log_aviso "arquivo não encontrado: $arq"; continue; }
        [[ -r "$arq" ]] || { log_aviso "sem permissão de leitura: $arq"; continue; }

        log_info "analisando: $arq (formato: $FORMATO)"
        
        # Versão simplificada - conta linhas, palavras, etc.
        local linhas palavras bytes
        linhas=$(wc -l < "$arq" 2>/dev/null || echo 0)
        palavras=$(wc -w < "$arq" 2>/dev/null || echo 0)
        bytes=$(wc -c < "$arq" 2>/dev/null || echo 0)
        
        if (( JSON_OUTPUT == 1 )); then
            local obj
            obj=$(jq -n --arg arq "$arq" --arg fmt "$FORMATO" --argjson linhas "$linhas" --argjson palavras "$palavras" --argjson bytes "$bytes" --arg ts "$(timestamp_iso)" \
                '{arquivo: $arq, formato: $fmt, linhas: $linhas, palavras: $palavras, bytes: $bytes, timestamp: $ts}')
            all_results=$(echo "$all_results" | jq -c --argjson o "$obj" '. + [$o]')
        else
            echo "=== $arq ==="
            echo "Formato: $FORMATO"
            echo "Linhas: $linhas"
            echo "Palavras: $palavras"
            echo "Bytes: $bytes"
            echo
        fi
    done

    if (( JSON_OUTPUT == 1 )); then
        echo "$all_results" | jq --arg ts "$(timestamp_iso)" '{timestamp: $ts, analises: .}'
    fi

    log_info "fim"
}

main "$@"