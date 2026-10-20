#!/usr/bin/env bash
#
# ferramenta.sh - script CLI com subcomandos.
#
# Uso: ./ferramenta.sh {status|limpa|info|ajuda}

[[ $# -ge 1 ]] || { echo "Uso: $0 {status|limpa|info|ajuda}" >&2; exit 2; }

subcomando="$1"
shift

case "$subcomando" in
    status)
        echo "=== Status do Sistema ==="
        echo "Uptime: $(uptime -p)"
        echo "Carga: $(awk '{print $1}' /proc/loadavg) (1 min)"
        echo "Disco:"
        df -h / | awk 'NR==2 {print "  Raiz: " $3 "/" $2 " (" $5 " usado)"}'
        ;;
    limpa)
        echo "=== Limpeza de /tmp (simulação - dry-run) ==="
        echo "Arquivos em /tmp mais velhos que 7 dias:"
        find /tmp -type f -mtime +7 -printf "  %p (%s bytes)\n" 2>/dev/null | head -20
        echo ""
        echo "Para executar realmente, use: find /tmp -type f -mtime +7 -delete"
        ;;
    info)
        echo "=== Informações do Sistema ==="
        echo "Hostname: $(hostname)"
        echo "Kernel:   $(uname -r)"
        if [[ -f /etc/os-release ]]; then
            # shellcheck source=/dev/null
            source /etc/os-release
            echo "Distro:   $PRETTY_NAME"
        fi
        echo "Arquitetura: $(uname -m)"
        echo "CPUs:     $(nproc)"
        echo "Memória:  $(free -h | awk 'NR==2 {print $2}')"
        ;;
    ajuda|help|-h|--help)
        echo "ferramenta.sh - Utilitário de administração simples"
        echo ""
        echo "Uso: $0 <subcomando>"
        echo ""
        echo "Subcomandos:"
        echo "  status   Mostra uptime, carga e uso de disco"
        echo "  limpa    Lista arquivos antigos em /tmp (dry-run)"
        echo "  info     Mostra hostname, kernel, distro, CPU, RAM"
        echo "  ajuda    Mostra esta ajuda"
        ;;
    *)
        echo "Subcomando inválido: $subcomando" >&2
        echo "Use '$0 ajuda' para ver opções." >&2
        exit 2
        ;;
esac