#!/usr/bin/env bash
#
# coleta-metricas.sh - Coleta métricas do sistema e exporta no formato Prometheus (textfile collector)
# Gera arquivo .prom para node_exporter consumir via --collector.textfile.directory
#
# Uso:
#   coleta-metricas.sh [-o|--output DIR] [-p|--prefixo NOME] [-h|--help]
#
# Opções:
#   -o, --output DIR    Diretório de saída (padrão: /var/lib/node_exporter/textfile_collector)
#   -p, --prefixo NOME  Prefixo do arquivo (padrão: sre_custom)
#   -h, --help          Exibe ajuda
#
# Métricas coletadas:
#   - CPU: uso, carga, núcleos
#   - Memória: total, usada, livre, swap
#   - Disco: uso por mountpoint
#   - Rede: bytes in/out, erros, drops por interface
#   - Processos: total, por estado, top CPU/mem
#   - Systemd: serviços failed/active
#   - Custom: uptime, kernel, distro
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   coleta-metricas.sh
#   coleta-metricas.sh -o /tmp/metrics -p meu_app
#   # No node_exporter: --collector.textfile.directory=/var/lib/node_exporter/textfile_collector

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

OUTPUT_DIR="/var/lib/node_exporter/textfile_collector"
PREFIXO="sre_custom"
ARQUIVO_SAIDA=""

# --- Log ---------------------------------------------------------------------
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

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha (código $c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }
usage() { sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'; }

# --- Escrita atômica ---
escreve_metrica() {
    local nome="$1" tipo="$2" valor="$3" labels="$4" ajuda="$5"
    printf '# HELP %s %s\n# TYPE %s %s\n%s{%s} %s\n\n' "$nome" "$ajuda" "$nome" "$tipo" "$nome" "$labels" "$valor"
}

# --- Coleta CPU ---
coleta_cpu() {
    local cpu_stat
    cpu_stat=$(grep "^cpu " /proc/stat)
    local user nice system idle iowait irq softirq steal guest guest_nice
    read -r _ user nice system idle iowait irq softirq steal guest guest_nice <<< "$cpu_stat"
    
    local total
    total=$(( user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice ))
    local uso=0
    [[ $total -gt 0 ]] && uso=$(( 100 - (idle * 100 / total) ))
    
    # Carga média
    local load1 load5 load15
    read -r load1 load5 load15 _ < /proc/loadavg
    
    # Núcleos
    local nucleos
    nucleos=$(grep -c "^processor" /proc/cpuinfo)
    
    escreve_metrica "node_cpu_usage_percent" "gauge" "$uso" "" "Uso total de CPU em porcentagem"
    escreve_metrica "node_load1" "gauge" "$load1" "" "Carga média 1 minuto"
    escreve_metrica "node_load5" "gauge" "$load5" "" "Carga média 5 minutos"
    escreve_metrica "node_load15" "gauge" "$load15" "" "Carga média 15 minutos"
    escreve_metrica "node_cpu_cores" "gauge" "$nucleos" "" "Número de núcleos de CPU"
}

# --- Coleta Memória ---
coleta_memoria() {
    local mem_total mem_free mem_available mem_buffers mem_cached swap_total swap_free
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
    mem_free=$(grep MemFree /proc/meminfo | awk '{print $2 * 1024}')
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2 * 1024}')
    mem_buffers=$(grep Buffers /proc/meminfo | awk '{print $2 * 1024}')
    mem_cached=$(grep ^Cached /proc/meminfo | awk '{print $2 * 1024}')
    swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2 * 1024}')
    swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2 * 1024}')
    
    local mem_used
    mem_used=$(( mem_total - mem_available ))
    local mem_pct=0
    [[ $mem_total -gt 0 ]] && mem_pct=$(( mem_used * 100 / mem_total ))
    
    local swap_used
    swap_used=$(( swap_total - swap_free ))
    local swap_pct=0
    [[ $swap_total -gt 0 ]] && swap_pct=$(( swap_used * 100 / swap_total ))
    
    escreve_metrica "node_memory_total_bytes" "gauge" "$mem_total" "" "Memória total em bytes"
    escreve_metrica "node_memory_used_bytes" "gauge" "$mem_used" "" "Memória usada em bytes"
    escreve_metrica "node_memory_free_bytes" "gauge" "$mem_free" "" "Memória livre em bytes"
    escreve_metrica "node_memory_available_bytes" "gauge" "$mem_available" "" "Memória disponível em bytes"
    escreve_metrica "node_memory_usage_percent" "gauge" "$mem_pct" "" "Uso de memória em porcentagem"
    escreve_metrica "node_memory_buffers_bytes" "gauge" "$mem_buffers" "" "Buffers em bytes"
    escreve_metrica "node_memory_cached_bytes" "gauge" "$mem_cached" "" "Cached em bytes"
    escreve_metrica "node_swap_total_bytes" "gauge" "$swap_total" "" "Swap total em bytes"
    escreve_metrica "node_swap_used_bytes" "gauge" "$swap_used" "" "Swap usada em bytes"
    escreve_metrica "node_swap_usage_percent" "gauge" "$swap_pct" "" "Uso de swap em porcentagem"
}

# --- Coleta Disco ---
coleta_disco() {
    df -P -B1 | tail -n +2 | while IFS= read -r linha; do
        local fs size used avail pct mount
        read -r fs size used avail pct mount <<< "$linha"
        pct=${pct%\%}
        
        local fs_clean
        fs_clean=$(echo "$fs" | sed 's/[^a-zA-Z0-9]/_/g')
        local mount_clean
        mount_clean=$(echo "$mount" | sed 's/[^a-zA-Z0-9]/_/g')
        
        escreve_metrica "node_filesystem_size_bytes" "gauge" "$size" "device=\"$fs_clean\",mountpoint=\"$mount_clean\",fstype=\"unknown\"" "Tamanho do filesystem em bytes"
        escreve_metrica "node_filesystem_used_bytes" "gauge" "$used" "device=\"$fs_clean\",mountpoint=\"$mount_clean\",fstype=\"unknown\"" "Espaço usado em bytes"
        escreve_metrica "node_filesystem_free_bytes" "gauge" "$avail" "device=\"$fs_clean\",mountpoint=\"$mount_clean\",fstype=\"unknown\"" "Espaço livre em bytes"
        escreve_metrica "node_filesystem_usage_percent" "gauge" "$pct" "device=\"$fs_clean\",mountpoint=\"$mount_clean\",fstype=\"unknown\"" "Uso do filesystem em porcentagem"
    done
}

# --- Coleta Rede ---
coleta_rede() {
    # /proc/net/dev
    awk 'NR>2 {
        iface=$1; gsub(/:/,"",iface)
        rx_bytes=$2; tx_bytes=$10
        rx_errs=$3; tx_errs=$11
        rx_drop=$4; tx_drop=$12
        printf "node_network_receive_bytes_total{device=\"%s\"} %d\n", iface, rx_bytes
        printf "node_network_transmit_bytes_total{device=\"%s\"} %d\n", iface, tx_bytes
        printf "node_network_receive_errs_total{device=\"%s\"} %d\n", iface, rx_errs
        printf "node_network_transmit_errs_total{device=\"%s\"} %d\n", iface, tx_errs
        printf "node_network_receive_drop_total{device=\"%s\"} %d\n", iface, rx_drop
        printf "node_network_transmit_drop_total{device=\"%s\"} %d\n", iface, tx_drop
    }' /proc/net/dev
}

# --- Coleta Processos ---
coleta_processos() {
    local total running sleeping zombie stopped
    total=$(ps aux --no-headers | wc -l)
    running=$(ps aux --no-headers | awk '$8 ~ /^R/ {c++} END {print c+0}')
    sleeping=$(ps aux --no-headers | awk '$8 ~ /^S/ {c++} END {print c+0}')
    zombie=$(ps aux --no-headers | awk '$8 ~ /^Z/ {c++} END {print c+0}')
    stopped=$(ps aux --no-headers | awk '$8 ~ /^T/ {c++} END {print c+0}')
    
    escreve_metrica "node_processes_total" "gauge" "$total" "" "Total de processos"
    escreve_metrica "node_processes_running" "gauge" "$running" "" "Processos rodando"
    escreve_metrica "node_processes_sleeping" "gauge" "$sleeping" "" "Processos dormindo"
    escreve_metrica "node_processes_zombie" "gauge" "$zombie" "" "Processos zumbis"
    escreve_metrica "node_processes_stopped" "gauge" "$stopped" "" "Processos parados"
    
    # Top 5 por CPU e MEM
    ps aux --sort=-%cpu | head -6 | tail -5 | while IFS= read -r linha; do
        local user pid cpu mem cmd
        read -r user pid cpu mem _ _ _ _ _ _ cmd <<< "$linha"
        cmd=$(echo "$cmd" | cut -c1-50 | sed 's/[^a-zA-Z0-9_.-]/_/g')
        escreve_metrica "node_process_cpu_percent" "gauge" "$cpu" "pid=\"$pid\",user=\"$user\",cmd=\"$cmd\"" "Uso de CPU do processo"
    done
    
    ps aux --sort=-%mem | head -6 | tail -5 | while IFS= read -r linha; do
        local user pid cpu mem cmd
        read -r user pid cpu mem _ _ _ _ _ _ cmd <<< "$linha"
        cmd=$(echo "$cmd" | cut -c1-50 | sed 's/[^a-zA-Z0-9_.-]/_/g')
        escreve_metrica "node_process_mem_percent" "gauge" "$mem" "pid=\"$pid\",user=\"$user\",cmd=\"$cmd\"" "Uso de memória do processo"
    done
}

# --- Coleta Systemd ---
coleta_systemd() {
    local failed active inactive
    failed=$(systemctl list-units --type=service --state=failed --no-legend 2>/dev/null | wc -l)
    active=$(systemctl list-units --type=service --state=active --no-legend 2>/dev/null | wc -l)
    inactive=$(systemctl list-units --type=service --state=inactive --no-legend 2>/dev/null | wc -l)
    
    escreve_metrica "node_systemd_failed_units" "gauge" "$failed" "" "Unidades systemd com falha"
    escreve_metrica "node_systemd_active_units" "gauge" "$active" "" "Unidades systemd ativas"
    escreve_metrica "node_systemd_inactive_units" "gauge" "$inactive" "" "Unidades systemd inativas"
}

# --- Info Sistema ---
coleta_sistema() {
    local uptime_sec kernel distro
    uptime_sec=$(cut -d. -f1 /proc/uptime)
    kernel=$(uname -r)
    distro=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "unknown")
    
    escreve_metrica "node_uptime_seconds" "gauge" "$uptime_sec" "" "Uptime do sistema em segundos"
    escreve_metrica "node_kernel_info" "gauge" "1" "kernel=\"$kernel\",distro=\"$distro\"" "Info do kernel e distro"
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output) OUTPUT_DIR="${2:-}"; shift 2 ;;
            -p|--prefixo) PREFIXO="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento: $1" 2 ;;
        esac
    done

    ARQUIVO_SAIDA="${OUTPUT_DIR}/${PREFIXO}.prom"
    local ARQUIVO_TEMP
    ARQUIVO_TEMP="${ARQUIVO_SAIDA}.tmp.$$"

    # Cria diretório se não existe
    mkdir -p "$OUTPUT_DIR" 2>/dev/null || die "não pode criar $OUTPUT_DIR (precisa root?)" 1
    [[ -w "$OUTPUT_DIR" ]] || die "sem permissão em $OUTPUT_DIR" 1

    log_info "coletando métricas -> $ARQUIVO_SAIDA"

    {
        echo "# Coletado em $(date -Iseconds) por $SCRIPT_NAME"
        echo "# Host: $(hostname)"
        echo
        
        coleta_cpu
        coleta_memoria
        coleta_disco
        coleta_rede
        coleta_processos
        coleta_systemd
        coleta_sistema
    } > "$ARQUIVO_TEMP"

    # Movimento atômico
    mv "$ARQUIVO_TEMP" "$ARQUIVO_SAIDA"
    
    log_info "métricas escritas em $ARQUIVO_SAIDA"
}

main "$@"