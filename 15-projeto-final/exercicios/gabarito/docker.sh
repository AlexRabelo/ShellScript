#!/usr/bin/env bash
#
# comandos/docker.sh - Gerenciamento de containers Docker
#
# Uso: sre-toolkit docker [-j|--json] [-v|--verbose] [--limpeza] [--stats] [-h|--help]
#
# Opções:
#   -j, --json       Saída JSON
#   -v, --verbose    Inclui detalhes
#   --limpeza        Remove images/containers/volumes dangling (docker system prune)
#   --stats          Mostra estatísticas de recursos (CPU/Memória)
#   -h, --help       Exibe ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito ausente

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"
source "${LIB_DIR}/util.sh"

JSON_OUTPUT=0
VERBOSE=0
FAZER_LIMPEZA=0
MOSTRAR_STATS=0

usage() {
    cat <<EOF
docker - Gerenciamento de containers Docker

Uso: sre-toolkit docker [-j|--json] [-v|--verbose] [--limpeza] [--stats] [-h|--help]

Opções:
  -j, --json       Saída JSON
  -v, --verbose    Inclui detalhes
  --limpeza        Remove images/containers/volumes dangling (docker system prune)
  --stats          Mostra estatísticas de recursos (CPU/Memória)
  -h, --help       Exibe ajuda
EOF
}

tem_docker() {
    command -v docker >/dev/null 2>&1 || { log_erro "Docker não instalado"; return 1; }
}

lista_containers() {
    local json_output="$1"
    tem_docker || return 1

    local containers_json
    containers_json=$(docker ps -a --format '{{json .}}' 2>/dev/null || echo "")

    if [[ -z "$containers_json" ]]; then
        if (( json_output == 1 )); then
            echo "[]"
        else
            echo "Nenhum container encontrado"
        fi
        return 0
    fi

    local results="[]"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if (( json_output == 1 )); then
            results=$(echo "$results" | jq -c --argjson c "$line" '. + [$c]')
        else
            local name status image
            name=$(echo "$line" | jq -r '.Names')
            status=$(echo "$line" | jq -r '.Status')
            image=$(echo "$line" | jq -r '.Image')
            printf "%-30s %-20s %s\n" "$name" "$status" "$image"
        fi
    done <<< "$containers_json"

    if (( json_output == 1 )); then
        echo "$results"
    fi
}

stats_containers() {
    local json_output="$1"
    tem_docker || return 1

    local stats_json
    stats_json=$(docker stats --no-stream --format '{{json .}}' 2>/dev/null || echo "")

    if [[ -z "$stats_json" ]]; then
        if (( json_output == 1 )); then
            echo "[]"
        else
            echo "Nenhum container rodando"
        fi
        return 0
    fi

    local results="[]"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if (( json_output == 1 )); then
            results=$(echo "$results" | jq -c --argjson s "$line" '. + [$s]')
        else
            local name cpu mem
            name=$(echo "$line" | jq -r '.Name')
            cpu=$(echo "$line" | jq -r '.CPUPerc')
            mem=$(echo "$line" | jq -r '.MemUsage')
            printf "%-30s CPU: %-10s MEM: %s\n" "$name" "$cpu" "$mem"
        fi
    done <<< "$stats_json"

    if (( json_output == 1 )); then
        echo "$results"
    fi
}

limpa_dangling() {
    tem_docker || return 1

    log_info "Executando limpeza Docker (docker system prune -f)..."
    run docker system prune -f

    if (( JSON_OUTPUT == 1 )); then
        jq -n --arg msg "Limpeza concluída" --arg ts "$(timestamp_iso)" \
            '{status: "ok", mensagem: $msg, timestamp: $ts}'
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            --limpeza) FAZER_LIMPEZA=1; shift ;;
            --stats) MOSTRAR_STATS=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) log_erro "Opção desconhecida: $1"; usage >&2; exit 2 ;;
        esac
    done

    log_info "início (json=$JSON_OUTPUT, limpeza=$FAZER_LIMPEZA, stats=$MOSTRAR_STATS)"

    if (( FAZER_LIMPEZA == 1 )); then
        limpa_dangling
    elif (( MOSTRAR_STATS == 1 )); then
        stats_containers "$JSON_OUTPUT"
    else
        lista_containers "$JSON_OUTPUT"
    fi

    log_info "fim"
}

main "$@"