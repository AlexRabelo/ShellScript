#!/usr/bin/env bash
#
# aws-inventory.sh - Inventário de recursos AWS (EC2, RDS, S3, ELB, Lambda)
# Usa AWS CLI v2 + jq para saída estruturada em JSON/texto.
#
# Uso:
#   aws-inventory.sh [-j|--json] [-r|--region REGIAO] [-p|--profile PERFIL]
#                   [-t|--tipo TIPO] [-h|--help]
#
# Tipos suportados: ec2, rds, s3, elb, lambda, all (padrão)
#
# Opções:
#   -j, --json       Saída JSON (padrão: texto)
#   -r, --region     Região AWS (padrão: variável AWS_DEFAULT_REGION ou us-east-1)
#   -p, --profile    Perfil AWS CLI (padrão: default)
#   -t, --tipo       Tipo de recurso: ec2, rds, s3, elb, lambda, all
#   -h, --help       Exibe ajuda
#
# Pré-requisitos:
#   - AWS CLI v2 instalado e configurado (aws configure)
#   - jq instalado
#   - Permissões IAM para listar recursos
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   aws-inventory.sh -j -t ec2
#   aws-inventory.sh -r us-west-2 -p prod -t all
#   aws-inventory.sh -j -t rds | jq '.[] | {id: .DBInstanceIdentifier, engine: .Engine, status: .DBInstanceStatus}'

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
PROFILE="default"
TIPO="all"

log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG) [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$msg" ;;
        *) [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$msg" ;;
    esac
}
log_info() { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro() { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando obrigatório: $1" 3; }
usage() { sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'; }

aws_cli() {
    aws --profile "$PROFILE" --region "$REGION" --output json "$@"
}

# --- Coletores ---
coleta_ec2() {
    log_debug "Coletando instâncias EC2..."
    aws_cli ec2 describe-instances \
        --query 'Reservations[].Instances[] | [].{InstanceId: InstanceId, InstanceType: InstanceType, State: State.Name, LaunchTime: LaunchTime, PrivateIp: PrivateIpAddress, PublicIp: PublicIpAddress, Tags: Tags, VpcId: VpcId, SubnetId: SubnetId, AvailabilityZone: Placement.AvailabilityZone}' \
        2>/dev/null || echo "[]"
}

coleta_rds() {
    log_debug "Coletando instâncias RDS..."
    aws_cli rds describe-db-instances \
        --query 'DBInstances[].{DBInstanceIdentifier: DBInstanceIdentifier, Engine: Engine, EngineVersion: EngineVersion, DBInstanceClass: DBInstanceClass, DBInstanceStatus: DBInstanceStatus, AllocatedStorage: AllocatedStorage, Endpoint: Endpoint.Address, Port: Endpoint.Port, MultiAZ: MultiAZ, VpcId: DBSubnetGroup.VpcId}' \
        2>/dev/null || echo "[]"
}

coleta_s3() {
    log_debug "Coletando buckets S3..."
    aws_cli s3api list-buckets \
        --query 'Buckets[].{Name: Name, CreationDate: CreationDate}' \
        2>/dev/null || echo "[]"
}

coleta_elb() {
    log_debug "Coletando Load Balancers..."
    local alb
    alb=$(aws_cli elbv2 describe-load-balancers --query 'LoadBalancers[].{Name: LoadBalancerName, ARN: LoadBalancerArn, Type: Type, State: State.Code, DNSName: DNSName, VpcId: VpcId, Scheme: Scheme}' 2>/dev/null || echo "[]")
    local clb
    clb=$(aws_cli elb describe-load-balancers --query 'LoadBalancerDescriptions[].{Name: LoadBalancerName, DNSName: DNSName, VpcId: VPCId, Scheme: Scheme}' 2>/dev/null || echo "[]")
    jq -n --argjson alb "$alb" --argjson clb "$clb" '{alb: $alb, clb: $clb}'
}

coleta_lambda() {
    log_debug "Coletando funções Lambda..."
    aws_cli lambda list-functions \
        --query 'Functions[].{FunctionName: FunctionName, Runtime: Runtime, Handler: Handler, MemorySize: MemorySize, Timeout: Timeout, LastModified: LastModified, CodeSize: CodeSize}' \
        2>/dev/null || echo "[]"
}

# --- Formata saída texto ---
formata_texto() {
    local tipo="$1" json="$2"
    
    case "$tipo" in
        ec2)
            echo "$json" | jq -r '.[] | "\(.InstanceId)\t\(.InstanceType)\t\(.State)\t\(.PrivateIp // "N/A")\t\(.PublicIp // "N/A")\t\(.AvailabilityZone)\t\(.Tags // [] | map("\(.Key)=\(.Value)") | join(","))"'
            ;;
        rds)
            echo "$json" | jq -r '.[] | "\(.DBInstanceIdentifier)\t\(.Engine)\t\(.EngineVersion)\t\(.DBInstanceClass)\t\(.DBInstanceStatus)\t\(.Endpoint // "N/A"):\(.Port // "N/A")\t\(.MultiAZ)"'
            ;;
        s3)
            echo "$json" | jq -r '.[] | "\(.Name)\t\(.CreationDate)"'
            ;;
        elb)
            echo "=== Application Load Balancers ==="
            echo "$json" | jq -r '.alb[] | "\(.Name)\t\(.Type)\t\(.State)\t\(.DNSName)\t\(.Scheme)"'
            echo "=== Classic Load Balancers ==="
            echo "$json" | jq -r '.clb[] | "\(.Name)\t\(.DNSName)\t\(.Scheme)"'
            ;;
        lambda)
            echo "$json" | jq -r '.[] | "\(.FunctionName)\t\(.Runtime)\t\(.MemorySize)MB\t\(.Timeout)s\t\(.LastModified)"'
            ;;
    esac
}

# --- Main ---
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -r|--region) REGION="${2:-}"; shift 2 ;;
            -p|--profile) PROFILE="${2:-}"; shift 2 ;;
            -t|--tipo) TIPO="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento: $1" 2 ;;
        esac
    done

    [[ "$TIPO" =~ ^(ec2|rds|s3|elb|lambda|all)$ ]] || die "tipo inválido: $TIPO" 2

    requer_comando aws
    requer_comando jq

    log_info "início (regiao=$REGION, profile=$PROFILE, tipo=$TIPO, json=$JSON_OUTPUT)"

    local all_results="{}"

    if [[ "$TIPO" == "ec2" || "$TIPO" == "all" ]]; then
        local ec2_json
        ec2_json=$(coleta_ec2)
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            all_results=$(echo "$all_results" | jq -c --argjson r "$ec2_json" '.ec2 = $r')
        else
            echo "=== EC2 Instances ==="
            echo "INSTANCE_ID	TYPE	STATE	PRIVATE_IP	PUBLIC_IP	AZ	TAGS"
            formata_texto ec2 "$ec2_json"
            echo
        fi
    fi

    if [[ "$TIPO" == "rds" || "$TIPO" == "all" ]]; then
        local rds_json
        rds_json=$(coleta_rds)
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            all_results=$(echo "$all_results" | jq -c --argjson r "$rds_json" '.rds = $r')
        else
            echo "=== RDS Instances ==="
            echo "ID	ENGINE	VERSION	CLASS	STATUS	ENDPOINT	MULTI_AZ"
            formata_texto rds "$rds_json"
            echo
        fi
    fi

    if [[ "$TIPO" == "s3" || "$TIPO" == "all" ]]; then
        local s3_json
        s3_json=$(coleta_s3)
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            all_results=$(echo "$all_results" | jq -c --argjson r "$s3_json" '.s3 = $r')
        else
            echo "=== S3 Buckets ==="
            echo "NAME	CREATION_DATE"
            formata_texto s3 "$s3_json"
            echo
        fi
    fi

    if [[ "$TIPO" == "elb" || "$TIPO" == "all" ]]; then
        local elb_json
        elb_json=$(coleta_elb)
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            all_results=$(echo "$all_results" | jq -c --argjson r "$elb_json" '.elb = $r')
        else
            formata_texto elb "$elb_json"
            echo
        fi
    fi

    if [[ "$TIPO" == "lambda" || "$TIPO" == "all" ]]; then
        local lambda_json
        lambda_json=$(coleta_lambda)
        if [[ "$JSON_OUTPUT" -eq 1 ]]; then
            all_results=$(echo "$all_results" | jq -c --argjson r "$lambda_json" '.lambda = $r')
        else
            echo "=== Lambda Functions ==="
            echo "NAME	RUNTIME	MEMORY	TIMEOUT	LAST_MODIFIED"
            formata_texto lambda "$lambda_json"
            echo
        fi
    fi

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        echo "$all_results" | jq --arg ts "$(date -Iseconds)" --arg region "$REGION" '. + {timestamp: $ts, region: $region}'
    fi

    log_info "fim"
}

main "$@"