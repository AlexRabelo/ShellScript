#!/usr/bin/env bash
# =============================================================================
# processa-aws-corrigido.sh — Versão corrigida sem avisos ShellCheck
# =============================================================================
# Autor: Alex Rabelo
# Versão: 1.0.0
# Descrição: Processa instâncias EC2 e tags AWS de forma segura.
# Uso: ./processa-aws-corrigido.sh
# Códigos de saída: 0 sucesso | 1 erro de execução | 3 dependência ausente
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        *) printf '%s\n' "$msg" ;;
    esac
}
log_info() { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro() { log ERRO "$@"; }
die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }

main() {
    requer_comando aws
    requer_comando jq

    log_info "início"

    # Busca instâncias
    local instances_json
    instances_json=$(aws ec2 describe-instances --output json 2>/dev/null) || die "falha ao descrever instâncias" 1

    # Extrai IDs e tipos de forma segura (SC2046, SC2086)
    local ids tipos
    mapfile -t ids < <(echo "$instances_json" | jq -r '.Reservations[].Instances[].InstanceId' 2>/dev/null)
    
    for id in "${ids[@]}"; do
        local tipo
        tipo=$(echo "$instances_json" | jq -r --arg id "$id" '.Reservations[].Instances[] | select(.InstanceId==$id) | .InstanceType' 2>/dev/null)
        printf 'ID: %s, Tipo: %s\n' "$id" "$tipo"
    done

    # Tags
    local tags_json
    tags_json=$(aws ec2 describe-tags --output json 2>/dev/null) || die "falha ao descrever tags" 1

    local count
    count=$(echo "$tags_json" | jq '.Tags | length' 2>/dev/null)
    echo "Total tags: $count"

    if (( count > 100 )); then
        echo "Muitas tags"
    fi

    log_info "fim"
}

main "$@"