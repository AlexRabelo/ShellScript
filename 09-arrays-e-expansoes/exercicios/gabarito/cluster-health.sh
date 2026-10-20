#!/usr/bin/env bash
#
# cluster-health.sh - Verifica saúde de cluster com arrays paralelos
#
# Uso: ./cluster-health.sh [-j] [-n] [-a ARQ_HOSTS] [-t TIMEOUT]
#
# Verifica conectividade SSH, uso de disco, memória e load de uma lista
# de hosts usando arrays indexados paralelos para armazenar resultados.
#
# Exemplo:
#   ./cluster-health.sh -a hosts.txt
#   ./cluster-health.sh -j -a hosts.txt | jq .
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
OUTPUT_JSON=0
ARQ_HOSTS="hosts.txt"
TIMEOUT_SSH=5

log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg
    msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO "$@" >&2; }

die() {
    local msg="$1"
    local codigo
    codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

cleanup() {
    local codigo=$?
    if [[ $codigo -eq 0 ]]; then
        log_info "terminou com sucesso"
    else
        log_erro "terminou com falha (código ${codigo})"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

usage() {
    sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'
}

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

# Função para executar comando remoto via SSH com timeout
ssh_exec() {
    local host="$1"
    local comando="$2"
    
    if (( DRY_RUN )); then
        # Em dry-run, retorna valores mockados baseado no hostname
        case "$host" in
            web*) echo "0|40|20|0.5";;
            db*)  echo "0|60|70|2.0";;
            bkp*) echo "0|30|15|0.2";;
            lb*)  echo "0|20|10|0.1";;
            *)    echo "0|50|50|1.0";;
        esac
        return 0
    fi
    
    local resultado
    resultado=$(ssh -o ConnectTimeout="$TIMEOUT_SSH" -o BatchMode=yes -o StrictHostKeyChecking=no "$host" "$comando" 2>/dev/null) || echo "1|0|0|0"
    echo "$resultado"
}

main() {
    # Processa opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -j|--json) OUTPUT_JSON=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -a|--hosts)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -a" 2
                ARQ_HOSTS="$2"; shift 2 ;;
            -t|--timeout)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -t" 2
                TIMEOUT_SSH="$2"; shift 2 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    [[ -r "$ARQ_HOSTS" ]] || die "não é possível ler o arquivo de hosts: $ARQ_HOSTS" 1

    requer_comando ssh || die "comando ssh não encontrado" 3
    requer_comando awk
    requer_comando printf

    log_info "início (hosts=$ARQ_HOSTS, timeout_ssh=$TIMEOUT_SSH, dry-run=$DRY_RUN, json=$OUTPUT_JSON)"

    # Arrays indexados paralelos
    declare -a hosts=()
    declare -a status_ssh=()      # 0=ok, 1=fail
    declare -a disk_usage=()      # percentual usado
    declare -a mem_usage=()       # percentual usado
    declare -a load_avg=()        # load average (1min)
    declare -a hostname_curto=()  # hostname curto do servidor

    # Lê hosts e coleta dados
    local i=0
    while IFS= read -r host || [[ -n "$host" ]]; do
        [[ -z "$host" ]] && continue  # ignora linhas vazias
        [[ "$host" =~ ^[[:space:]]*# ]] && continue  # ignora comentários
        
        host="$(echo -n "$host" | xargs)"  # remove espaços
        hosts[i]="$host"
        
        # Extrai hostname curto para uso nos comandos
        hostname_curto[i]=$(ssh_exec "$host" "hostname -s 2>/dev/null || hostname 2>/dev/null || echo 'unknown'")
        
        # Executa verificações remotas (tudo em uma chamada SSH para eficiência)
        local verificacao
        verificacao=$(ssh_exec "$host" "
            # SSH status
            echo -n '0|'
            
            # Uso de disco (%)
            df -h / | awk 'NR==2 {gsub(\"%\",\"\",\$5); print \$5}'
            echo -n '|'
            
            # Uso de memória (%)
            free | awk 'NR==2 {printf \"%.0f\", \$3*100/\$2 }'
            echo -n '|'
            
            # Load average (1min)
            uptime | awk -F'load average:' '{print \$2}' | awk '{print \$1}'
        ")
        
        # Parse resultado: ssh_status|disk%|mem%|load
        IFS='|' read -r ssh_status disk mem load <<< "$verificacao"
        
        status_ssh[i]="$ssh_status"
        disk_usage[i]="$disk"
        mem_usage[i]="$mem"
        load_avg[i]="$load"
        
        (( i++ ))
    done < "$ARQ_HOSTS"

    local total_hosts
    total_hosts=${#hosts[@]}
    log_info "processados $total_hosts hosts"

    # Saída
    if (( OUTPUT_JSON )); then
        # Constrói array de objetos JSON
        local json_array=""
        for (( idx=0; idx<total_hosts; idx++ )); do
            json_array+=$(printf '{"host":"%s","ssh_ok":%s,"disk_usage":%s,"mem_usage":%s,"load_avg":%s},' \
                "${hosts[$idx]}" "${status_ssh[$idx]}" "${disk_usage[$idx]}" "${mem_usage[$idx]}" "${load_avg[$idx]}")
        done
        # Remove última vírgula e envolve em array
        json_array="${json_array%,}"
        printf '[%s]\n' "$json_array" | jq .
    else
        # Saída legível com alertas
        echo "=== Cluster Health Check ==="
        echo "Arquivo de hosts: $ARQ_HOSTS"
        echo "Total de hosts: $total_hosts"
        echo

        # Tabela de resultados
        printf "%-20s %-8s %-8s %-8s %-8s %-10s\n" "HOST" "SSH" "DISK%" "MEM%" "LOAD" "STATUS"
        printf "%-20s %-8s %-8s %-8s %-8s %-10s\n" "----" "--" "----" "----" "----" "------"
        
        local alertas=0
        for (( idx=0; idx<total_hosts; idx++ )); do
            local status="OK"
            local disk_num
            disk_num=${disk_usage[$idx]%%.*}
            local mem_num
            mem_num=${mem_usage[$idx]%%.*}
            local load_num
            load_num=$(echo "${load_avg[$idx]}" | awk '{print int($1)}')
            
            # Determina status baseado em thresholds
            if [[ "${status_ssh[$idx]}" -ne 0 ]]; then
                status="SSH_FAIL"
                ((alertas++))
            elif [[ "$disk_num" -ge 90 ]]; then
                status="DISK_HIGH"
                ((alertas++))
            elif [[ "$mem_num" -ge 85 ]]; then
                status="MEM_HIGH"
                ((alertas++))
            elif [[ "$load_num" -gt 4 ]]; then  # assume até 4 núcleos
                status="LOAD_HIGH"
                ((alertas++))
            fi
            
            printf "%-20s %-8s %-8s %-8s %-8s %-10s\n" \
                "${hosts[$idx]}" "${status_ssh[$idx]}" "${disk_usage[$idx]}" "${mem_usage[$idx]}" "${load_avg[$idx]}" "$status"
        done
        
        echo
        if (( alertas > 0 )); then
            echo "⚠️  $alertas host(s) com problemas detectados"
            echo "   - SSH_FAIL: não responde a SSH"
            echo "   - DISK_HIGH: uso de disco ≥ 90%"
            echo "   - MEM_HIGH: uso de memória ≥ 85%"
            echo "   - LOAD_HIGH: load average > 4"
        else
            echo "✅ Todos os hosts estão saudáveis"
        fi
    fi

    log_info "fim"
}

main "$@"