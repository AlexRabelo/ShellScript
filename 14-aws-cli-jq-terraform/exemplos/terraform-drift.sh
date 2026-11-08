#!/usr/bin/env bash
#
# terraform-drift.sh - Detecta drift entre estado Terraform e infraestrutura real
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   terraform-drift.sh [-j|--json] [-d|--dir DIRETORIO] [-r|--region REGIAO]
#                     [-p|--profile PERFIL] [-t|--tipo TIPO] [-h|--help]
#
# Opções:
#   -j, --json       Saída JSON
#   -d, --dir        Diretório do projeto Terraform (padrão: .)
#   -r, --region     Região AWS
#   -p, --profile    Perfil AWS CLI
#   -t, --tipo       Tipo de recurso: ec2, rds, s3, iam, sg, all
#   -h, --help       Exibe ajuda
#
# Pré-requisitos:
#   - Terraform instalado e inicializado (terraform init)
#   - AWS CLI v2 + jq
#   - Estado remoto ou local acessível
#
# Códigos de saída:
#   0 sem drift | 1 drift detectado | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   ./terraform-drift.sh -j -t all
#   ./terraform-drift.sh -d ./infra/prod -t ec2
#   ./terraform-drift.sh -j | jq '.drift[] | select(.tipo=="aws_instance")'
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
TF_DIR="."
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
PROFILE="default"
TIPO="all"

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
log_debug() { [[ "$JSON_OUTPUT" -eq 0 ]] && log DEBUG "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }
usage() { sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'; }

aws_cli() {
    aws --profile "$PROFILE" --region "$REGION" --output json "$@"
}

# Extrai recursos do estado Terraform
estado_terraform() {
    cd "$TF_DIR" || die "diretório não encontrado: $TF_DIR" 1
    terraform state list 2>/dev/null | while IFS= read -r recurso; do
        terraform state show "$recurso" 2>/dev/null | jq -c --arg r "$recurso" '{tipo: (split(".")[0]), nome: $r, atributos: .}'
    done
}

# Compara instâncias EC2
drift_ec2() {
    log_debug "Verificando drift EC2..."

    # Estado TF: instâncias gerenciadas
    local tf_instances
    tf_instances=$(cd "$TF_DIR" && terraform state list 2>/dev/null | grep '^aws_instance\.' || true)

    if [[ -z "$tf_instances" ]]; then
        echo "[]"
        return
    fi

    local drift_list="[]"

    while IFS= read -r nome_tf; do
        [[ -z "$nome_tf" ]] && continue

        # Extrai ID da instância do estado
        local instance_id
        instance_id=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^id' | head -1 | sed 's/.*= "//; s/"$//' || echo "")

        if [[ -z "$instance_id" ]]; then
            drift_list=$(echo "$drift_list" | jq -c --arg t "aws_instance" --arg n "$nome_tf" --arg s "not_in_state" '. + [{tipo: $t, nome: $n, status: $s, detalhe: "ID não encontrado no estado"}]')
            continue
        fi

        # Consulta AWS real
        local aws_data
        aws_data=$(aws_cli ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[0].Instances[0].{InstanceId: InstanceId, State: State.Name, InstanceType: InstanceType, Tags: Tags}' 2>/dev/null || echo "null")

        if [[ "$aws_data" == "null" ]]; then
            drift_list=$(echo "$drift_list" | jq -c --arg t "aws_instance" --arg n "$nome_tf" --arg s "missing" --arg id "$instance_id" '. + [{tipo: $t, nome: $n, status: $s, instance_id: $id, detalhe: "Instância não existe na AWS"}]')
        else
            local state
            state=$(echo "$aws_data" | jq -r '.State')
            if [[ "$state" != "running" && "$state" != "stopped" ]]; then
                drift_list=$(echo "$drift_list" | jq -c --arg t "aws_instance" --arg n "$nome_tf" --arg s "state_mismatch" --arg id "$instance_id" --arg state "$state" '. + [{tipo: $t, nome: $n, status: $s, instance_id: $id, estado_aws: $state, detalhe: "Estado inesperado"}]')
            fi
        fi
    done <<< "$tf_instances"

    echo "$drift_list"
}

# Compara RDS
drift_rds() {
    log_debug "Verificando drift RDS..."
    local tf_dbs
    tf_dbs=$(cd "$TF_DIR" && terraform state list 2>/dev/null | grep '^aws_db_instance\.' || true)

    [[ -z "$tf_dbs" ]] && { echo "[]"; return; }

    local drift_list="[]"

    while IFS= read -r nome_tf; do
        [[ -z "$nome_tf" ]] && continue
        local db_id
        db_id=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^identifier' | head -1 | sed 's/.*= "//; s/"$//' || echo "")

        [[ -z "$db_id" ]] && continue

        local aws_data
        aws_data=$(aws_cli rds describe-db-instances --db-instance-identifier "$db_id" --query 'DBInstances[0].{DBInstanceIdentifier: DBInstanceIdentifier, DBInstanceStatus: DBInstanceStatus, Engine: Engine, DBInstanceClass: DBInstanceClass}' 2>/dev/null || echo "null")

        if [[ "$aws_data" == "null" ]]; then
            drift_list=$(echo "$drift_list" | jq -c --arg t "aws_db_instance" --arg n "$nome_tf" --arg s "missing" --arg id "$db_id" '. + [{tipo: $t, nome: $n, status: $s, resource_id: $id, detalhe: "RDS não existe na AWS"}]')
        fi
    done <<< "$tf_dbs"

    echo "$drift_list"
}

# Compara S3
drift_s3() {
    log_debug "Verificando drift S3..."
    local tf_buckets
    tf_buckets=$(cd "$TF_DIR" && terraform state list 2>/dev/null | grep '^aws_s3_bucket\.' || true)

    [[ -z "$tf_buckets" ]] && { echo "[]"; return; }

    local drift_list="[]"

    while IFS= read -r nome_tf; do
        [[ -z "$nome_tf" ]] && continue
        local bucket_name
        bucket_name=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^bucket' | head -1 | sed 's/.*= "//; s/"$//' || echo "")

        [[ -z "$bucket_name" ]] && continue

        if ! aws_cli s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
            drift_list=$(echo "$drift_list" | jq -c --arg t "aws_s3_bucket" --arg n "$nome_tf" --arg s "missing" --arg id "$bucket_name" '. + [{tipo: $t, nome: $n, status: $s, resource_id: $id, detalhe: "Bucket não existe na AWS"}]')
        fi
    done <<< "$tf_buckets"

    echo "$drift_list"
}

# Compara Security Groups
drift_sg() {
    log_debug "Verificando drift Security Groups..."
    local tf_sgs
    tf_sgs=$(cd "$TF_DIR" && terraform state list 2>/dev/null | grep '^aws_security_group\.' || true)

    [[ -z "$tf_sgs" ]] && { echo "[]"; return; }

    local drift_list="[]"

    while IFS= read -r nome_tf; do
        [[ -z "$nome_tf" ]] && continue
        local sg_id
        sg_id=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^id' | head -1 | sed 's/.*= "//; s/"$//' || echo "")

        [[ -z "$sg_id" ]] && continue

        if ! aws_cli ec2 describe-security-groups --group-ids "$sg_id" >/dev/null 2>&1; then
            drift_list=$(echo "$drift_list" | jq -c --arg t "aws_security_group" --arg n "$nome_tf" --arg s "missing" --arg id "$sg_id" '. + [{tipo: $t, nome: $n, status: $s, resource_id: $id, detalhe: "Security Group não existe na AWS"}]')
        fi
    done <<< "$tf_sgs"

    echo "$drift_list"
}

# Compara IAM
drift_iam() {
    log_debug "Verificando drift IAM..."
    local tf_iam
    tf_iam=$(cd "$TF_DIR" && terraform state list 2>/dev/null | grep -E '^aws_iam_(role|policy|user|group)\.' || true)

    [[ -z "$tf_iam" ]] && { echo "[]"; return; }

    local drift_list="[]"

    while IFS= read -r nome_tf; do
        [[ -z "$nome_tf" ]] && continue
        local tipo_tf
        tipo_tf=$(echo "$nome_tf" | cut -d'.' -f1)
        local nome
        case "$tipo_tf" in
            aws_iam_role) nome=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^name' | head -1 | sed 's/.*= "//; s/"$//') ;;
            aws_iam_policy) nome=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^name' | head -1 | sed 's/.*= "//; s/"$//') ;;
            aws_iam_user) nome=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^name' | head -1 | sed 's/.*= "//; s/"$//') ;;
            aws_iam_group) nome=$(cd "$TF_DIR" && terraform state show "$nome_tf" 2>/dev/null | grep '^name' | head -1 | sed 's/.*= "//; s/"$//') ;;
        esac

        [[ -z "$nome" ]] && continue

        local existe=false
        case "$tipo_tf" in
            aws_iam_role) aws_cli iam get-role --role-name "$nome" >/dev/null 2>&1 && existe=true ;;
            aws_iam_policy) aws_cli iam get-policy --policy-arn "$(aws_cli iam list-policies --query "Policies[?PolicyName=='$nome'].Arn" --output text 2>/dev/null)" >/dev/null 2>&1 && existe=true ;;
            aws_iam_user) aws_cli iam get-user --user-name "$nome" >/dev/null 2>&1 && existe=true ;;
            aws_iam_group) aws_cli iam get-group --group-name "$nome" >/dev/null 2>&1 && existe=true ;;
        esac

        if [[ "$existe" == "false" ]]; then
            drift_list=$(echo "$drift_list" | jq -c --arg t "$tipo_tf" --arg n "$nome_tf" --arg s "missing" --arg id "$nome" '. + [{tipo: $t, nome: $n, status: $s, resource_id: $id, detalhe: "Recurso IAM não existe na AWS"}]')
        fi
    done <<< "$tf_iam"

    echo "$drift_list"
}

# --- Lógica Principal --------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -d|--dir) TF_DIR="${2:-}"; shift 2 ;;
            -r|--region) REGION="${2:-}"; shift 2 ;;
            -p|--profile) PROFILE="${2:-}"; shift 2 ;;
            -t|--tipo) TIPO="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento: $1" 2 ;;
        esac
    done

    [[ "$TIPO" =~ ^(ec2|rds|s3|iam|sg|all)$ ]] || die "tipo inválido: $TIPO" 2
    [[ -d "$TF_DIR" ]] || die "diretório não existe: $TF_DIR" 1

    requer_comando terraform
    requer_comando aws
    requer_comando jq

    cd "$TF_DIR" || die "não pode acessar $TF_DIR" 1
    terraform version >/dev/null 2>&1 || die "terraform não inicializado" 3

    log_info "início (dir=$TF_DIR, regiao=$REGION, tipo=$TIPO)"

    local all_drift="[]"
    local drift_count=0

    if [[ "$TIPO" == "ec2" || "$TIPO" == "all" ]]; then
        local d
        d=$(drift_ec2)
        all_drift=$(echo "$all_drift" | jq -c --argjson x "$d" '. + $x')
    fi

    if [[ "$TIPO" == "rds" || "$TIPO" == "all" ]]; then
        local d
        d=$(drift_rds)
        all_drift=$(echo "$all_drift" | jq -c --argjson x "$d" '. + $x')
    fi

    if [[ "$TIPO" == "s3" || "$TIPO" == "all" ]]; then
        local d
        d=$(drift_s3)
        all_drift=$(echo "$all_drift" | jq -c --argjson x "$d" '. + $x')
    fi

    if [[ "$TIPO" == "sg" || "$TIPO" == "all" ]]; then
        local d
        d=$(drift_sg)
        all_drift=$(echo "$all_drift" | jq -c --argjson x "$d" '. + $x')
    fi

    if [[ "$TIPO" == "iam" || "$TIPO" == "all" ]]; then
        local d
        d=$(drift_iam)
        all_drift=$(echo "$all_drift" | jq -c --argjson x "$d" '. + $x')
    fi

    drift_count=$(echo "$all_drift" | jq 'length')

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n --argjson drift "$all_drift" --arg ts "$(date -Iseconds)" --arg count "$drift_count" --arg dir "$TF_DIR" --arg region "$REGION" \
            '{timestamp: $ts, directory: $dir, region: $region, drift_count: ($count|tonumber), drift: $drift}'
    else
        if [[ $drift_count -eq 0 ]]; then
            log_info "Nenhum drift detectado"
        else
            log_aviso "Drift detectado: $drift_count recurso(s)"
            echo "$all_drift" | jq -r '.[] | "[\(.tipo)] \(.nome) -> \(.status): \(.detalhe)"'
        fi
    fi

    log_info "fim (drift=$drift_count)"
    [[ $drift_count -eq 0 ]] || exit 1
}

main "$@"