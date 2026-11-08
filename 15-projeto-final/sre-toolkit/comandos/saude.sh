#!/usr/bin/env bash
#
# comandos/saude.sh - Relatório de saúde do servidor
#
# Uso: sre-toolkit saude [-j|--json] [-v|--verbose] [-h|--help]

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"
source "${LIB_DIR}/util.sh"

JSON_OUTPUT=0
VERBOSE=0

usage() {
    cat <<EOF
saude - Relatório de saúde do servidor

Uso: sre-toolkit saude [-j|--json] [-v|--verbose] [-h|--help]

Opções:
  -j, --json       Saída JSON
  -v, --verbose    Inclui detalhes extras
  -h, --help       Exibe ajuda
EOF
}

coleta_sistema() {
    local hn up kernel distro
    hn=$(host_curto)
    up=$(cut -d. -f1 /proc/uptime)
    kernel=$(uname -r)
    distro=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"' || echo 'unknown')
    
    jq -n --arg hn "$hn" --arg up "$up" --arg kernel "$kernel" --arg distro "$distro" \
        '{hostname: $hn, uptime_seconds: ($up|tonumber), kernel: $kernel, distro: $distro}'
}

coleta_cpu() {
    local cpu_stat
    cpu_stat=$(grep "^cpu " /proc/stat)
    local user nice system idle iowait irq softirq steal
    read -r _ user nice system idle iowait irq softirq steal _ <<< "$cpu_stat"
    local total=$(( user + nice + system + idle + iowait + irq + softirq + steal ))
    local uso=$(( 100 - (idle * 100 / total) ))
    local load1 load5 load15
    load1=$(awk '{print $1}' /proc/loadavg)
    load5=$(awk '{print $2}' /proc/loadavg)
    load15=$(awk '{print $3}' /proc/loadavg)
    local nucleos
    nucleos=$(grep -c "^processor" /proc/cpuinfo)
    jq -n --argjson uso "$uso" --argjson n "$nucleos" --argjson l1 "$load1" --argjson l5 "$load5" --argjson l15 "$load15" \
        '{uso_percentual: $uso, nucleos: $n, carga_media: {um_min: $l1, cinco_min: $l5, quinze_min: $l15}}'
}

coleta_memoria() {
    local mem_total mem_free mem_avail swap_total swap_free
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
    mem_free=$(grep MemFree /proc/meminfo | awk '{print $2 * 1024}')
    mem_avail=$(grep MemAvailable /proc/meminfo | awk '{print $2 * 1024}')
    swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2 * 1024}')
    swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2 * 1024}')
    
    local mem_usada=$(( mem_total - mem_avail ))
    local mem_pct=0
    (( mem_total > 0 )) && mem_pct=$(( mem_usada * 100 / mem_total ))
    
    local swap_usada=$(( swap_total - swap_free ))
    local swap_pct=0
    (( swap_total > 0 )) && swap_pct=$(( swap_usada * 100 / swap_total ))
    
    jq -n --argjson total "$mem_total" --argjson usada "$mem_usada" --argjson livre "$mem_avail" --argjson pct "$mem_pct" \
        --argjson swap_total "$swap_total" --argjson swap_usada "$swap_usada" --argjson swap_pct "$swap_pct" \
        '{total_bytes: $total, usada_bytes: $usada, disponivel_bytes: $livre, uso_percentual: $pct, swap: {total_bytes: $swap_total, usada_bytes: $swap_usada, uso_percentual: $swap_pct}}'
}

coleta_disco() {
    df -P / 2>/dev/null | tail -n +2 | while IFS= read -r linha; do
        local fs size used avail pct mount
        read -r fs size used avail pct mount <<< "$linha"
        pct=${pct%\%}
        jq -n --arg fs "$fs" --argjson size "$size" --argjson used "$used" --argjson avail "$avail" --argjson pct "$pct" --arg mount "$mount" \
            '{filesystem: $fs, total_bytes: $size, usado_bytes: $used, livre_bytes: $avail, uso_percentual: $pct, montado_em: $mount}'
    done | jq -s '.'
}

coleta_processos() {
    local total running sleeping zombie
    total=$(ps aux --no-headers | wc -l)
    running=$(ps aux --no-headers | awk '$8 ~ /^R/ {c++} END {print c+0}')
    sleeping=$(ps aux --no-headers | awk '$8 ~ /^S/ {c++} END {print c+0}')
    zombie=$(ps aux --no-headers | awk '$8 ~ /^Z/ {c++} END {print c+0}')
    
    jq -n --argjson total "$total" --argjson running "$running" --argjson sleeping "$sleeping" --argjson zombie "$zombie" \
        '{total: $total, running: $running, sleeping: $sleeping, zombie: $zombie}'
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) log_erro "Opção desconhecida: $1"; usage >&2; exit 2 ;;
        esac
    done

    log_info "coletando métricas de saúde (json=$JSON_OUTPUT)"

    local sys cpu mem disk proc
    sys=$(coleta_sistema)
    cpu=$(coleta_cpu)
    mem=$(coleta_memoria)
    disk=$(coleta_disco)
    proc=$(coleta_processos)

    if (( JSON_OUTPUT == 1 )); then
        jq -n --argjson sys "$sys" --argjson cpu "$cpu" --argjson mem "$mem" --argjson disk "$disk" --argjson proc "$proc" --arg ts "$(timestamp_iso)" \
            '{timestamp: $ts, sistema: $sys, cpu: $cpu, memoria: $mem, disco: $disk, processos: $proc}'
    else
        echo "=== SAÚDE DO SERVIDOR ==="
        echo "$sys" | jq -r '"Hostname: \(.hostname)\nUptime: \(.uptime_seconds)s\nKernel: \(.kernel)\nDistro: \(.distro)"'
        echo
        echo "$cpu" | jq -r '"CPU: \(.uso_percentual)% (\(.nucleos) cores) | Carga: \(.carga_media.um_min) \(.carga_media.cinco_min) \(.carga_media.quinze_min)"'
        echo
        echo "$mem" | jq -r '"RAM: \(.uso_percentual)% (\(.usada_bytes|tostring)B/\(.total_bytes|tostring)B) | Swap: \(.swap.uso_percentual)%"'
        echo
        echo "DISCO:"
        echo "$disk" | jq -r '.[] | "\(.filesystem): \(.uso_percentual)% (\(.usado_bytes|tostring)B/\(.total_bytes|tostring)B) em \(.montado_em)"'
        echo
        echo "$proc" | jq -r '"Processos: \(.total) total (\(.running) running, \(.sleeping) sleeping, \(.zombie) zombie)"'
    fi

    log_info "fim"
}

main "$@"