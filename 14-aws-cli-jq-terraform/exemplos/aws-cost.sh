#!/usr/bin/env bash
#
# aws-cost.sh - Análise de custos AWS (Cost Explorer)
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   aws-cost.sh [-j|--json] [-r|--region REGIAO] [-p|--profile PERFIL]
#              [-d|--dias N] [-g|--group-by DIMENSAO] [-h|--help]
#
# Opções:
#   -j, --json       Saída JSON
#   -r, --region     Região (Cost Explorer é global, usa us-east-1)
#   -p, --profile    Perfil AWS CLI
#   -d, --dias N     Período em dias (padrão: 30)
#   -g, --group-by   Agrupa por: SERVICE, LINKED_ACCOUNT, REGION, USAGE_TYPE (padrão: SERVICE)
#   -h, --help       Exibe ajuda
#
# Pré-requisitos:
#   - AWS CLI v2 + Cost Explorer habilitado
#   - Permissão: ce:GetCostAndUsage, ce:GetDimensionValues
#   - jq instalado
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   ./aws-cost.sh -d 7 -g SERVICE
#   ./aws-cost.sh -j -d 90 -g LINKED_ACCOUNT
#   ./aws-cost.sh -g REGION -d 30 | jq '.[] | select(.amount > 10)'
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
REGION="us-east-1"
PROFILE="default"
DIAS=30
GROUP_BY="SERVICE"

log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        *) [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$msg" ;;
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
usage() { sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'; }

aws_ce() {
    aws --profile "$PROFILE" --region "$REGION" --output json ce "$@"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -r|--region) REGION="${2:-}"; shift 2 ;;
            -p|--profile) PROFILE="${2:-}"; shift 2 ;;
            -d|--dias) DIAS="${2:-}"; shift 2 ;;
            -g|--group-by) GROUP_BY="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento: $1" 2 ;;
        esac
    done

    if [[ ! "$DIAS" =~ ^[0-9]+$ ]] || (( DIAS <= 0 )); then
        die "dias inválido: $DIAS" 2
    fi
    [[ "$GROUP_BY" =~ ^(SERVICE|LINKED_ACCOUNT|REGION|USAGE_TYPE)$ ]] || die "group-by inválido: $GROUP_BY" 2

    requer_comando aws
    requer_comando jq

    local end_date
    end_date=$(date -u +%Y-%m-%d)
    local start_date
    start_date=$(date -u -d "-${DIAS} days" +%Y-%m-%d)

    log_info "consultando custos ($start_date a $end_date, grupo=$GROUP_BY)"

    local query
    query=$(aws_ce get-cost-and-usage \
        --time-period Start="${start_date}",End="${end_date}" \
        --granularity DAILY \
        --metrics UnblendedCost \
        --group-by Type=DIMENSION,Key="${GROUP_BY}" 2>/dev/null) || die "falha ao consultar Cost Explorer" 1

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        echo "$query" | jq --arg ts "$(date -Iseconds)" --arg period "${start_date}/${end_date}" '. + {timestamp: $ts, period: $period}'
    else
        echo "$query" | jq -r --arg group "$GROUP_BY" '
            .ResultsByTime[] |
            .Groups[] |
            "\(.Keys[0])\t\(.Metrics.UnblendedCost.Amount | tonumber | . * 100 | floor / 100)\t\(.Metrics.UnblendedCost.Unit)"
        ' | sort -k2 -nr | awk -F'\t' -v grp="$GROUP_BY" 'BEGIN{print grp "\tCOST (USD)\tCURRENCY"} {print $1 "\t" $2 "\t" $3}'
    fi

    log_info "fim"
}

main "$@"