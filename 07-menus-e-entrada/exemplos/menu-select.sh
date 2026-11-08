#!/usr/bin/env bash
#
# menu-select.sh - Menu interativo usando o builtin select do bash
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   menu-select.sh
#
# Códigos de saída:
#   0  Sucesso
#
# Exemplos:
#   ./menu-select.sh
#
# Demonstra:
#   - Builtin select do bash para menus numerados
#   - Loop que continua até break ser executado
#   - Validação de entrada do usuário
#   - Cores ANSI para melhor experiência visual
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
# SCRIPT_DIR disponível para scripts que precisam do diretório do script
# readonly SCRIPT_DIR
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

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
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
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
        AMARELO='\033[1;33m'
        VERMELHO='\033[1;31m'
        RESET='\033[0m'
    else
        AMARELO=''; VERMELHO=''; RESET=''
    fi

    PS3="Escolha uma opção [1-4]: "
    select opcao in "Status do Sistema" "Gerenciar Serviço" "Ver Logs Recentes" "Sair"; do
        case "$opcao" in
            "Status do Sistema")
                echo -e "${AMARELO}--- Status do Sistema ---${RESET}"
                echo "Hostname: $(hostname)"
                echo "Uptime:   $(uptime -p)"
                echo "Carga:    $(awk '{print $1\" (1min), \"$2\" (5min), \"$3\" (15min)\"}' /proc/loadavg)"
                echo "Disco:    $(df -h / | awk 'NR==2 {print $3\"/\"$2\" (\"$5\" usado)\"}')"
                echo "Memória:  $(free -h | awk 'NR==2 {print $3\"/\"$2}')"
                echo
                ;;
            "Gerenciar Serviço")
                echo -e "${AMARELO}--- Gerenciar Serviço ---${RESET}"
                read -rp "Nome do serviço (ex: nginx, sshd): " servico
                [[ -z "$servico" ]] && { echo "Nome vazio."; continue; }

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
                ;;
            "Ver Logs Recentes")
                echo -e "${AMARELO}--- Logs Recentes (últimas 20 linhas) ---${RESET}"
                echo "=== /var/log/syslog ==="
                tail -20 /var/log/syslog 2>/dev/null || journalctl -n 20 --no-pager 2>/dev/null || echo "Logs não acessíveis"
                echo
                ;;
            "Sair")
                echo "Saindo..."
                break
                ;;
            *) echo -e "${VERMELHO}Opção inválida: $REPLY${RESET}" >&2 ;;
        esac
    done

    log_info "fim"
}

main "$@"