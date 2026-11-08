#!/usr/bin/env bash
#
# comandos/incidente.sh - Coleta de diagnóstico para troubleshooting
#
# Uso: sre-toolkit incidente [--coleta-completa] [--dir DIR] [-j|--json] [-v|--verbose] [-h|--help]

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"
source "${LIB_DIR}/util.sh"

COLETA_COMPLETA=0
DIR_OUTPUT="/tmp/incidente-$(date +%F-%H%M%S)"
JSON_OUTPUT=0
VERBOSE=0

usage() {
    cat <<EOF
incidente - Coleta de diagnóstico para troubleshooting

Uso: sre-toolkit incidente [--coleta-completa] [--dir DIR] [-j|--json] [-v|--verbose] [-h|--help]

Opções:
  --coleta-completa  Inclui dumps de memória, stack traces, etc.
  --dir DIR          Diretório de saída (padrão: /tmp/incidente-YYYYMMDD-HHMMSS)
  -j, --json         Saída JSON
  -v, --verbose      Inclui detalhes
  -h, --help         Exibe ajuda
EOF
}

coleta_basica() {
    local dir="$1"
    mkdir -p "$dir"
    
    # Informações do sistema
    run uname -a > "$dir/system_info.txt"
    run lsb_release -a 2>/dev/null || cat /etc/os-release > "$dir/os_info.txt" || true
    run hostnamectl status > "$dir/hostname_info.txt" 2>/dev/null || true
    
    # Uso de recursos
    run top -b -n 1 > "$dir/top.txt"
    run ps aux --sort=-%cpu | head -20 > "$dir/top_cpu.txt"
    run ps aux --sort=-%mem | head -20 > "$dir/top_mem.txt"
    run df -h > "$dir/disk_usage.txt"
    run free -h > "$dir/memory_usage.txt"
    run netstat -tulnp 2>/dev/null || ss -tulnp 2>/dev/null || echo "netstat/ss não disponível" > "$dir/network_ports.txt"
    
    # Serviços
    run systemctl list-units --type=service --state=running > "$dir/services_running.txt" 2>/dev/null || true
    run systemctl list-units --type=service --state=failed > "$dir/services_failed.txt" 2>/dev/null || true
    
    # Logs recentes
    run journalctl --since "1 hour ago" --no-pager -n 1000 > "$dir/journald_recent.txt" 2>/dev/null || true
    
    log_info "coleta básica concluída em $dir"
}

coleta_completa() {
    local dir="$1"
    coleta_basica "$dir"
    
    # Informações avançadas
    run lspci -vv > "$dir/pci_info.txt" 2>/dev/null || true
    run lsusb -v > "$dir/usb_info.txt" 2>/dev/null || true
    run dmidecode > "$dir/dmi_info.txt" 2>/dev/null || true
    
    # Core dumps (se houver)
    run find /var/crash -type f -name "*.core" -o -name "*core.*" 2>/dev/null | head -5 > "$dir/core_files.txt" || true
    
    log_info "coleta completa concluída em $dir"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --coleta-completa) COLETA_COMPLETA=1; shift ;;
            --dir) DIR_OUTPUT="${2:-}"; shift 2 ;;
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) log_erro "Opção desconhecida: $1"; usage >&2; exit 2 ;;
        esac
    done

    log_info "início (coleta_completa=$COLETA_COMPLETA, dir=$DIR_OUTPUT)"

    if (( COLETA_COMPLETA == 1 )); then
        coleta_completa "$DIR_OUTPUT"
    else
        coleta_basica "$DIR_OUTPUT"
    fi

    if (( JSON_OUTPUT == 1 )); then
        jq -n --arg dir "$DIR_OUTPUT" --arg completo "$COLETA_COMPLETA" --arg ts "$(timestamp_iso)" \
            '{diretorio: $dir, coleta_completa: ($completo|tonumber), timestamp: $ts, mensagem: "Coleta de incidente concluída"}'
    else
        echo "=== COLETA DE INCIDENTE CONCLUÍDA ==="
        echo "Diretório: $DIR_OUTPUT"
        echo "Tipo: $([[ $COLETA_COMPLETA == 1 ]] && echo "Completa" || echo "Básica")"
        echo
        echo "Coleta inclui:"
        echo "  - Informações do sistema e OS"
        echo "  - Uso de recursos (top, ps, df, free)"
        echo "  - Portas de rede abertas"
        echo "  - Serviços systemd (running/failed)"
        echo "  - Logs do journalctl (última hora)"
        [[ $COLETA_COMPLETA == 1 ]] && echo "  - Informações de hardware (PCI, USB, DMI)"
        [[ $COLETA_COMPLETA == 1 ]] && echo "  - Arquivos de core dump (se existirem)"
        echo
        echo "Próximos passos:"
        echo "  1. Examine os arquivos em $DIR_OUTPUT"
        echo "  2. Compacte para envio: tar -czf incidente.tar.gz $DIR_OUTPUT"
        echo "  3. Anlene ao ticket de suporte"
    fi

    log_info "fim"
}

main "$@"