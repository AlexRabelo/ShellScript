#!/usr/bin/env bash
#
# menu-simples.sh - menu interativo manual com while + case.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   menu-simples.sh
#
# Exibe um menu simples de administração com opções para verificar status do sistema,
# gerenciar serviços, visualizar logs e sair.
#
# Exemplos:
#   ./menu-simples.sh
#
# =============================================================================

set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

# --- Funções de Log ----------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

# --- Limpeza e Tratamento de Sinais ------------------------------------------
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

# --- Utilidades --------------------------------------------------------------
requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] $*"
        return 0
    else
        log_debug "executando: $*"
        "$@"
    fi
}

usage() {
    sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE)"

    # Configuração de cores
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
        VERDE='\033[1;32m'
        AMARELO='\033[1;33m'
        VERMELHO='\033[1;31m'
        AZUL='\033[1;34m'
        RESET='\033[0m'
    else
        VERDE=''; AMARELO=''; VERMELHO=''; AZUL=''; RESET=''
    fi

    mostra_menu() {
        echo -e "${AZUL}=== MENU DE ADMINISTRAÇÃO ===${RESET}"
        echo "1) ${VERDE}Status do Sistema${RESET}"
        echo "2) ${VERDE}Gerenciar Serviço${RESET}"
        echo "3) ${VERDE}Ver Logs Recentes${RESET}"
        echo "4) ${VERMELHO}Sair${RESET}"
        echo
    }

    status_sistema() {
        echo -e "${AMARELO}--- Status do Sistema ---${RESET}"
        echo "Hostname: $(hostname)"
        echo "Uptime:   $(uptime -p)"
        echo "Carga:    $(awk '{print $1\" (1min), \"$2\" (5min), \"$3\" (15min)\"}' /proc/loadavg)"
        echo "Disco:    $(df -h / | awk 'NR==2 {print $3\"/\"$2\" (\"$5\" usado)\"}')"
        echo "Memória:  $(free -h | awk 'NR==2 {print $3\"/\"$2}')"
        echo
    }

    gerencia_servico() {
        echo -e "${AMARELO}--- Gerenciar Serviço ---${RESET}"
        read -rp "Nome do serviço (ex: nginx, sshd): " servico
        [[ -z "$servico" ]] && { echo "Nome vazio."; return; }

        echo "Ações: start | stop | restart | status"
        read -rp "Ação: " acao

        case "$acao" in
            start|stop|restart|status)
                echo "Executando: systemctl $acao $servico"
                # systemctl "$acao" "$servico"  # descomente para real
                ;;
            *) echo "Ação inválida: $acao" ;;
        esac
        echo
    }

    ver_logs() {
        echo -e "${AMARELO}--- Logs Recentes (últimas 20 linhas) ---${RESET}"
        echo "=== /var/log/syslog ==="
        tail -20 /var/log/syslog 2>/dev/null || journalctl -n 20 --no-pager 2>/dev/null || echo "Logs não acessíveis"
        echo
    }

    # Loop principal
    while true; do
        mostra_menu
        read -rp "Escolha [1-4]: " opcao
        case "$opcao" in
            1) status_sistema ;;
            2) gerencia_servico ;;
            3) ver_logs ;;
            4) echo "Saindo..."; exit 0 ;;
            *) echo -e "${VERMELHO}Opção inválida: $opcao${RESET}" >&2 ;;
        esac
        echo
    done

    log_info "fim"
}

main "$@"