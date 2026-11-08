#!/usr/bin/env bash
#
# comandos/disco.sh - Análise e limpeza de disco
#
# Uso: sre-toolkit disco [--limpeza] [--dias N] [--dir DIR] [-j|--json] [-v|--verbose] [-h|--help]

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"
source "${LIB_DIR}/util.sh"

JSON_OUTPUT=0
VERBOSE=0
FAZER_LIMPEZA=0
DIAS=30
DIR_ALVO="/tmp"

usage() {
    cat <<EOF
disco - Análise e limpeza de disco

Uso: sre-toolkit disco [--limpeza] [--dias N] [--dir DIR] [-j|--json] [-v|--verbose] [-h|--help]

Opções:
  --limpeza     Executa limpeza (padrão: apenas analisa)
  --dias N      Arquivos com mais de N dias (padrão: 30)
  --dir DIR     Diretório para analisar/limpar (padrão: /tmp)
  -j, --json    Saída JSON
  -v, --verbose  Inclui detalhes
  -h, --help    Exibe ajuda
EOF
}

analisa_disco() {
    local dir="$1" dias="$2"
    local total_arquivos=0 total_tamanho=0
    local arquivos_antigos=0 tamanho_antigo=0
    local detalhes="[]"
    
    while IFS= read -r -d '' arquivo; do
        [[ -z "$arquivo" ]] && continue
        ((total_arquivos++))
        local tamanho
        tamanho=$(stat -c%s "$arquivo" 2>/dev/null || echo 0)
        total_tamanho=$(( total_tamanho + tamanho ))
        
        local modificacao
        modificacao=$(stat -c%Y "$arquivo" 2>/dev/null || echo 0)
        local agora
        agora=$(date +%s)
        local idade=$(( agora - modificacao ))
        
        if (( idade > dias * 86400 )); then
            ((arquivos_antigos++))
            tamanho_antigo=$(( tamanho_antigo + tamanho ))
            detalhes=$(echo "$detalhes" | jq -c --arg p "$arquivo" --argjson t "$tamanho" --argjson i "$idade" '. + [{path: $p, size_bytes: $t, idade_dias: ($i/86400|floor)}]')
        fi
    done < <(find "$dir" -type f -print0 2>/dev/null)
    
    jq -n --arg dir "$dir" --arg dias "$dias" \
        --argjson total_arquivos "$total_arquivos" --argjson total_tamanho "$total_tamanho" \
        --argjson arquivos_antigos "$arquivos_antigos" --argjson tamanho_antigo "$tamanho_antigo" \
        --argjson detalhes "$detalhes" \
        '{diretorio: $dir, dias_limite: $dias, total_arquivos: $total_arquivos, total_tamanho_bytes: $total_tamanho, arquivos_mais_antigos: $arquivos_antigos, tamanho_antigo_bytes: $tamanho_antigo, detalhes: $detalhes}'
}

limpa_disco() {
    local dir="$1" dias="$2"
    local count=0
    
    while IFS= read -r -d '' arquivo; do
        [[ -z "$arquivo" ]] && continue
        local modificacao
        modificacao=$(stat -c%Y "$arquivo" 2>/dev/null || echo 0)
        local agora
        agora=$(date +%s)
        local idade=$(( agora - modificacao ))
        
        if (( idade > dias * 86400 )); then
            run rm -f -- "$arquivo"
            ((count++))
        fi
    done < <(find "$dir" -type f -print0 2>/dev/null)
    
    echo "$count"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limpeza) FAZER_LIMPEZA=1; shift ;;
            --dias) DIAS="${2:-}"; shift 2 ;;
            --dir) DIR_ALVO="${2:-}"; shift 2 ;;
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) log_erro "Opção desconhecida: $1"; usage >&2; exit 2 ;;
        esac
    done

    valida_diretorio "$DIR_ALVO" || exit 1
    valida_numero "$DIAS" "dias" || exit 2

    log_info "início (dir=$DIR_ALVO, dias=$DIAS, limpeza=$FAZER_LIMPEZA)"

    local resultado
    resultado=$(analisa_disco "$DIR_ALVO" "$DIAS")

    if (( FAZER_LIMPEZA == 1 )); then
        log_info "iniciando limpeza..."
        local removidos
        removidos=$(limpa_disco "$DIR_ALVO" "$DIAS")
        log_info "limpeza concluída: $removidos arquivo(s) removido(s)"
        
        if (( JSON_OUTPUT == 1 )); then
            resultado=$(echo "$resultado" | jq -c --argjson removidos "$removidos" '. + {limpeza: {arquivos_removidos: $removidos}}')
        fi
    fi

    if (( JSON_OUTPUT == 1 )); then
        echo "$resultado" | jq --arg ts "$(timestamp_iso)" '. + {timestamp: $ts}'
    else
        echo "=== ANÁLISE DE DISCO: $DIR_ALVO ==="
        echo "Diretório: $DIR_ALVO"
        echo "Limite de idade: $DIAS dias"
        echo "Total de arquivos: $(echo "$resultado" | jq -r '.total_arquivos')"
        echo "Tamanho total: $(bytes_humano $(echo "$resultado" | jq -r '.total_tamanho_bytes'))"
        echo
        echo "Arquivos com mais de $DIAS dias: $(echo "$resultado" | jq -r '.arquivos_mais_antigos')"
        echo "Tamanho desses arquivos: $(bytes_humano $(echo "$resultado" | jq -r '.tamanho_antigo_bytes'))"
        if (( FAZER_LIMPEZA == 1 )); then
            echo "Arquivos removidos na limpeza: $(echo "$resultado" | jq -r '.limpeza.arquivos_removidos // 0')"
        fi
        echo
        if (( FAZER_LIMPEZA == 1 )) && (( $(echo "$resultado" | jq -r '.arquivos_mais_antigos') > 0 )); then
            echo "Primeiros 10 arquivos mais antigos:"
            echo "$resultado" | jq -r '.detalhes[] | "\(.path) \(.tamanho_bytes)B \(.idade_dias)dias"' | head -10
        fi
    fi

    log_info "fim"
}

main "$@"