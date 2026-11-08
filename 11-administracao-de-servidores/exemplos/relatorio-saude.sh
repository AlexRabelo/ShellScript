#!/usr/bin/env bash
#
# relatorio-saude.sh - Relatório de saúde do servidor (CPU, RAM, disco, carga, processos)
# Gera saída em texto (padrão) ou JSON (-j). Útil para monitoramento, alertas e inventário.
#
# Uso:
#   relatorio-saude.sh [-j|--json] [-v|--verbose] [-h|--help]
#
# Opções:
#   -j, --json      Saída em JSON (padrão: texto)
#   -v, --verbose   Inclui detalhes extras (top 10 processos, montagens, network)
#   -h, --help      Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro genérico | 2 uso incorreto | 3 pré-requisito ausente
#
# Exemplos:
#   relatorio-saude.sh                    # Relatório texto no stdout
#   relatorio-saude.sh -j > saude.json    # JSON para API/arquivo
#   relatorio-saude.sh -v                 # Relatório detalhado
#   relatorio-saude.sh -j -v | jq .       # JSON formatado

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
VERBOSE=0

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      if [[ "$VERBOSE" -eq 1 ]]; then printf '%s\n' "$msg"; fi ;;
        *)          [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() {
    local codigo="${2:-1}"
    log_erro "$1"
    exit "$codigo"
}

# --- Utilidades --------------------------------------------------------------
requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

# Lê valor do /proc/meminfo em kB
ler_meminfo() {
    grep "^$1:" /proc/meminfo | awk '{print $2}'
}

# Converte kB para bytes
kb_para_bytes() {
    echo $(( ${1:-0} * 1024 ))
}

# Formata bytes em humano (KB, MB, GB, TB)
bytes_humano() {
    local bytes="${1:-0}"
    local unidades=(B KB MB GB TB)
    local i=0
    while (( bytes >= 1024 && i < ${#unidades[@]} - 1 )); do
        bytes=$(( bytes / 1024 ))
        ((i++))
    done
    echo "${bytes} ${unidades[i]}"
}

# --- Coleta de métricas ------------------------------------------------------
coletar_cpu() {
    local cpu_info
    cpu_info=$(lscpu 2>/dev/null || true)

    local modelo nucleos threads_por_nucleo sockets
    modelo=$(echo "$cpu_info" | grep "Model name:" | cut -d: -f2 | sed 's/^ *//')
    nucleos=$(echo "$cpu_info" | grep "^CPU(s):" | awk '{print $2}')
    threads_por_nucleo=$(echo "$cpu_info" | grep "Thread(s) per core:" | awk '{print $4}')
    sockets=$(echo "$cpu_info" | grep "Socket(s):" | awk '{print $2}')

# Carga média (1, 5, 15 min)
    local carga_1 carga_5 carga_15
    read -r carga_1 carga_5 carga_15 _ < /proc/loadavg

    # Uso de CPU (user, nice, system, idle, iowait, irq, softirq, steal)
    local cpu_stat
    cpu_stat=$(grep "^cpu " /proc/stat)
    local user nice system idle iowait irq softirq steal
    read -r _ user nice system idle iowait irq softirq steal _ <<< "$cpu_stat"

    local total=$(( user + nice + system + idle + iowait + irq + softirq + steal ))
    local uso=$(( 100 - (idle * 100 / total) ))

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n \
            --arg modelo "$modelo" \
            --argjson nucleos "$nucleos" \
            --argjson threads "$threads_por_nucleo" \
            --argjson sockets "$sockets" \
            --argjson carga1 "$carga_1" \
            --argjson carga5 "$carga_5" \
            --argjson carga15 "$carga_15" \
            --argjson uso "$uso" \
            '{modelo: $modelo, nucleos: $nucleos, threads_por_nucleo: $threads, sockets: $sockets, carga_media: {um_min: $carga1, cinco_min: $carga5, quinze_min: $carga15}, uso_percentual: $uso}'
    else
        echo "=== CPU ==="
        echo "Modelo:        ${modelo:-desconhecido}"
        echo "Núcleos:       ${nucleos:-?} (${threads_por_nucleo:-?} threads/núcleo, ${sockets:-?} socket(s))"
        echo "Carga média:   ${carga_1} (1min)  ${carga_5} (5min)  ${carga_15} (15min)"
        echo "Uso atual:     ${uso}%"
        echo
    fi
}

coletar_memoria() {
local mem_total_kb mem_disponivel_kb mem_usada_kb
    local swap_total_kb swap_livre_kb swap_usada_kb

    mem_total_kb=$(ler_meminfo MemTotal)
    mem_livre_kb=$(ler_meminfo MemFree)
    mem_disponivel_kb=$(ler_meminfo MemAvailable)
    swap_total_kb=$(ler_meminfo SwapTotal)
    swap_livre_kb=$(ler_meminfo SwapFree)

    mem_usada_kb=$(( mem_total_kb - mem_disponivel_kb ))
    swap_usada_kb=$(( swap_total_kb - swap_livre_kb ))

    local mem_total_b mem_usada_b mem_disponivel_b
    local swap_total_b swap_usada_b swap_livre_b
    mem_total_b=$(kb_para_bytes "$mem_total_kb")
    mem_usada_b=$(kb_para_bytes "$mem_usada_kb")
    mem_disponivel_b=$(kb_para_bytes "$mem_disponivel_kb")
    swap_total_b=$(kb_para_bytes "$swap_total_kb")
    swap_usada_b=$(kb_para_bytes "$swap_usada_kb")
    swap_livre_b=$(kb_para_bytes "$swap_livre_kb")

    local mem_uso_pct=0
    [[ $mem_total_kb -gt 0 ]] && mem_uso_pct=$(( mem_usada_kb * 100 / mem_total_kb ))
    local swap_uso_pct=0
    [[ $swap_total_kb -gt 0 ]] && swap_uso_pct=$(( swap_usada_kb * 100 / swap_total_kb ))

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n \
            --argjson total "$mem_total_b" \
            --argjson usada "$mem_usada_b" \
            --argjson disponivel "$mem_disponivel_b" \
            --argjson uso_pct "$mem_uso_pct" \
            --argjson swap_total "$swap_total_b" \
            --argjson swap_usada "$swap_usada_b" \
            --argjson swap_livre "$swap_livre_b" \
            --argjson swap_uso_pct "$swap_uso_pct" \
            '{total_bytes: $total, usada_bytes: $usada, disponivel_bytes: $disponivel, uso_percentual: $uso_pct, swap: {total_bytes: $swap_total, usada_bytes: $swap_usada, livre_bytes: $swap_livre, uso_percentual: $swap_uso_pct}}'
    else
        echo "=== MEMÓRIA ==="
        echo "Total:         $(bytes_humano "$mem_total_b")"
        echo "Usada:         $(bytes_humano "$mem_usada_b") (${mem_uso_pct}%)"
        echo "Disponível:    $(bytes_humano "$mem_disponivel_b")"
        if [[ $swap_total_kb -gt 0 ]]; then
            echo "Swap total:    $(bytes_humano "$swap_total_b")"
            echo "Swap usada:    $(bytes_humano "$swap_usada_b") (${swap_uso_pct}%)"
            echo "Swap livre:    $(bytes_humano "$swap_livre_b")"
        else
            echo "Swap:          não configurado"
        fi
        echo
    fi
}

coletar_disco() {
    local df_saida
    df_saida=$(df -P -B1 --output=source,fstype,size,used,avail,pcent,target / 2>/dev/null | tail -n +2)

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        local json_array="[]"
        while IFS= read -r linha; do
            [[ -z "$linha" ]] && continue
            local dispositivo fs tamanho usado disponivel uso_pct ponto
            read -r dispositivo fs tamanho usado disponivel uso_pct ponto <<< "$linha"
            uso_pct=${uso_pct%\%}
            json_array=$(echo "$json_array" | jq -c --arg dev "$dispositivo" --arg fs "$fs" --argjson tam "$tamanho" --argjson us "$usado" --argjson disp "$disponivel" --argjson pct "$uso_pct" --arg mp "$ponto" '. + [{"dispositivo": $dev, "filesystem": $fs, "total_bytes": $tam, "usado_bytes": $us, "livre_bytes": $disp, "uso_percentual": $pct, "ponto_montagem": $mp}]')
        done <<< "$df_saida"
        echo "$json_array" | jq -c '{discos: .}'
    else
        echo "=== DISCO (/) ==="
        echo "$df_saida" | while IFS= read -r linha; do
            [[ -z "$linha" ]] && continue
            local dispositivo fs tamanho usado disponivel uso_pct ponto
            read -r dispositivo fs tamanho usado disponivel uso_pct ponto <<< "$linha"
            echo "Dispositivo:   $dispositivo ($fs)"
            echo "Total:         $(bytes_humano "$tamanho")"
            echo "Usado:         $(bytes_humano "$usado") ($uso_pct)"
            echo "Livre:         $(bytes_humano "$disponivel")"
            echo "Montado em:    $ponto"
            echo
        done
    fi

    # Verboso: todas as montagens
    if [[ "$VERBOSE" -eq 1 && "$JSON_OUTPUT" -eq 0 ]]; then
        echo "=== TODAS MONTAGENS ==="
        df -h -P --output=source,fstype,size,used,avail,pcent,target | column -t
        echo
    fi
}

coletar_rede() {
    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        local json_array="[]"
        # Interfaces com IP
        ip -j addr show 2>/dev/null | jq -c '.[] | select(.addr_info != null) | {interface: .ifname, mac: .address, ips: [.addr_info[].local]}' | while IFS= read -r iface_json; do
            json_array=$(echo "$json_array" | jq -c --argjson iface "$iface_json" '. + [$iface]')
        done
        # Portas escutando
        local portas_json="[]"
        ss -tulpn -j 2>/dev/null | jq -c '.[] | {protocolo: .protocol, porta: .local_address.port, processo: .process, pid: .pid}' | while IFS= read -r porta_json; do
            portas_json=$(echo "$portas_json" | jq -c --argjson p "$porta_json" '. + [$p]')
        done
        jq -n --argjson ifaces "$json_array" --argjson portas "$portas_json" '{interfaces: $ifaces, portas_escutando: $portas}'
    else
        echo "=== REDE ==="
        echo "Interfaces:"
        ip -brief addr show | grep -v "lo " | while IFS= read -r linha; do
            echo "  $linha"
        done
        echo
        echo "Portas escutando (TCP/UDP):"
        ss -tulpn | head -20
        echo
    fi
}

coletar_processos() {
    local total_procs procs_rodando procs_dormindo procs_zumbi
    total_procs=$(ps aux --no-headers | wc -l)
    procs_rodando=$(ps aux --no-headers | awk '$8 ~ /^R/ {count++} END {print count+0}')
    procs_dormindo=$(ps aux --no-headers | awk '$8 ~ /^S/ {count++} END {print count+0}')
    procs_zumbi=$(ps aux --no-headers | awk '$8 ~ /^Z/ {count++} END {print count+0}')

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        local top_json="[]"
        if [[ "$VERBOSE" -eq 1 ]]; then
ps aux --sort=-%cpu | head -11 | tail -10 | while IFS= read -r linha; do
                local user pid cpu mem stat time cmd
                read -r user pid cpu mem stat time cmd <<< "$linha"
                top_json=$(echo "$top_json" | jq -c --arg u "$user" --argjson p "$pid" --argjson c "$cpu" --argjson m "$mem" --arg s "$stat" --arg t "$time" --arg c2 "$cmd" '. + [{"usuario": $u, "pid": $p, "cpu_pct": $c, "mem_pct": $m, "estado": $s, "tempo": $t, "comando": $c2}]')
            done
        fi
        jq -n --argjson total "$total_procs" --argjson rodando "$procs_rodando" --argjson dormindo "$procs_dormindo" --argjson zumbi "$procs_zumbi" --argjson top "$top_json" '{total: $total, rodando: $rodando, dormindo: $dormindo, zumbi: $zumbi, top_cpu: $top}'
    else
        echo "=== PROCESSOS ==="
        echo "Total:         $total_procs"
        echo "Rodando:       $procs_rodando"
        echo "Dormindo:      $procs_dormindo"
        echo "Zumbis:        $procs_zumbi"
        if [[ "$VERBOSE" -eq 1 ]]; then
            echo
            echo "Top 10 por CPU:"
            ps aux --sort=-%cpu | head -11 | column -t
        fi
        echo
    fi
}

coletar_sistema() {
    local hostname uptime_seg kernel distro
    hostname=$(hostname)
    uptime_seg=$(cut -d. -f1 /proc/uptime)
    kernel=$(uname -r)
    distro=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "desconhecido")

    local dias=$(( uptime_seg / 86400 ))
    local horas=$(( (uptime_seg % 86400) / 3600 ))
    local mins=$(( (uptime_seg % 3600) / 60 ))

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        jq -n --arg hn "$hostname" --arg up "$uptime_seg" --arg k "$kernel" --arg d "$distro" --argjson dias "$dias" --argjson hrs "$horas" --argjson mins "$mins" '{hostname: $hn, uptime_segundos: ($up|tonumber), kernel: $k, distro: $d, uptime_human: "\($dias)d \($hrs)h \($mins)m"}'
    else
        echo "=== SISTEMA ==="
        echo "Hostname:      $hostname"
        echo "Uptime:        ${dias}d ${horas}h ${mins}m (${uptime_seg}s)"
        echo "Kernel:        $kernel"
        echo "Distro:        $distro"
        echo
    fi
}

# --- Saída principal ---------------------------------------------------------
gerar_relatorio_texto() {
    coletar_sistema
    coletar_cpu
    coletar_memoria
    coletar_disco
    [[ "$VERBOSE" -eq 1 ]] && coletar_rede
    coletar_processos
}

gerar_relatorio_json() {
    local json_sistema json_cpu json_mem json_disco json_procs json_rede
    json_sistema=$(coletar_sistema)
    json_cpu=$(coletar_cpu)
    json_mem=$(coletar_memoria)
    json_disco=$(coletar_disco)
    json_procs=$(coletar_processos)
    [[ "$VERBOSE" -eq 1 ]] && json_rede=$(coletar_rede) || json_rede='{}'

    jq -n \
        --argjson sys "$json_sistema" \
        --argjson cpu "$json_cpu" \
        --argjson mem "$json_mem" \
        --argjson disk "$json_disco" \
        --argjson procs "$json_procs" \
        --argjson net "$json_rede" \
        --arg timestamp "$(date -Iseconds)" \
        '{timestamp: $timestamp, sistema: $sys, cpu: $cpu, memoria: $mem, discos: $disk, processos: $procs, rede: $net}'
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) die "argumento não esperado: $1" 2 ;;
        esac
    done

    [[ "$JSON_OUTPUT" -eq 1 ]] && requer_comando jq
    requer_comando lscpu
    requer_comando df
    requer_comando ps
    requer_comando ip
    requer_comando ss

    log_info "início (json=$JSON_OUTPUT, verbose=$VERBOSE)"

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        gerar_relatorio_json
    else
        gerar_relatorio_texto
    fi

    log_info "fim"
}

main "$@"