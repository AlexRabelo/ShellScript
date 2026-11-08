#!/usr/bin/env bash
#
# menu-sysadmin.sh - Menu completo de administração de servidor
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   menu-sysadmin.sh
#
# Argumentos:
#   (nenhum)
#
# Códigos de saída:
#   0  Sucesso
#
# Exemplos:
#   ./menu-sysadmin.sh
#
# Demonstra:
#   - Menu profissional com validação
#   - Cores ANSI para interface melhorada
#   - Ações reais do sistema (quando não em modo dry-run)
#   - Uso de bibliotecas auxiliares (log.sh, valida.sh)
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

# Variáveis de controle
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
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$msg" ;;
        *)          printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO  "$@"; }
log_sucesso() { log OK    "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO  "$@"; }
log_debug() { log DEBUG "$@"; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

# --- Limpeza e Tratamento de Sinais ------------------------------------------
cleanup() {
    local codigo=$?
    # Limpeza de recursos temporários aqui
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
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

# --- Funções auxiliares ------------------------------------------------------

mostra_cabecalho() {
    echo -e "${AZUL}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║   MENU DE ADMINISTRAÇÃO - $(hostname -s)   ║${RESET}"
    echo -e "${AZUL}╚══════════════════════════════════════════╝${RESET}"
    echo
}

mostra_menu() {
    echo "1) ${VERDE}Saúde do Sistema${RESET}       (disco, memória, carga, uptime)"
    echo "2) ${VERDE}Gerenciar Serviço${RESET}        (start/stop/restart/status)"
    echo "3) ${VERDE}Ver Logs Críticos${RESET}        (últimas 50 linhas)"
    echo "4) ${VERDE}Testar Conectividade${RESET}     (ping/porta)"
    echo "5) ${VERDE}Top Processos${RESET}            (CPU/Memória)"
    echo "6) ${VERMELHO}Sair${RESET}"
    echo
}

opcao_saude() {
    log_info "Coletando saúde do sistema..."
    echo
    echo "=== Disco ==="
    df -h / | awk 'NR==1 || NR==2'
    echo
    echo "=== Memória ==="
    free -h
    echo
    echo "=== Carga ==="
    uptime
    echo
    echo "=== Inodes ==="
    df -i / | awk 'NR==1 || NR==2'
    echo
}

opcao_servico() {
    read -rp "Nome do serviço: " servico
    [[ -z "$servico" ]] && { log_aviso "Nome vazio"; return; }

    if ! systemctl list-unit-files "${servico}.service" >/dev/null 2>&1; then
        log_erro "Serviço '$servico' não encontrado"
        return
    fi

    echo "Ações: start | stop | restart | status | enable | disable"
    read -rp "Ação: " acao

    case "$acao" in
        start|stop|restart|status|enable|disable)
            log_info "Executando: systemctl $acao $servico"
            systemctl "$acao" "$servico" || log_erro "Falha ao executar $acao"
            ;;
        *) log_erro "Ação inválida: $acao" ;;
    esac
}

opcao_logs() {
    echo "=== Últimas 50 linhas do journal (prioridade err/emerg/alert/crit) ==="
    journalctl -p 3 -n 50 --no-pager 2>/dev/null || tail -50 /var/log/syslog 2>/dev/null
}

opcao_conectividade() {
    read -rp "Host/IP: " host
    [[ -z "$host" ]] && { log_aviso "Host vazio"; return; }

    read -rp "Porta (opcional, Enter=pula): " porta

    # Teste ping
    log_info "Testando ping em $host..."
    if [[ "$DRY_RUN" -eq 0 ]]; then
        if ping -c 2 -W 2 "$host" >/dev/null 2>&1; then
            log_sucesso "PING OK"
        else
            log_erro "PING FALHOU"
        fi
    else
        log_info "[DRY-RUN] ping -c 2 -W 2 $host"
    fi

    # Teste porta se fornecida
    if [[ -n "$porta" ]]; then
        if [[ "$porta" =~ ^[0-9]+$ ]] && (( porta >= 1 && porta <= 65535 )); then
            log_info "Testando porta $porta em $host..."
            if [[ "$DRY_RUN" -eq 0 ]]; then
                if porta_aberta "$host" "$porta"; then
                    log_sucesso "PORTA $porta ABERTA"
                else
                    log_erro "PORTA $porta FECHADA"
                fi
            else
                log_info "[DRY-RUN] porta_aberta $host $porta"
            fi
        else
            log_erro "Porta inválida: $porta"
        fi
    fi
}

opcao_processos() {
    echo "=== Top 10 por CPU ==="
    ps aux --sort=-%cpu | head -11
    echo
    echo "=== Top 10 por Memória ==="
    ps aux --sort=-%mem | head -11
}

# --- Configuração de cores ---------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    VERDE='\033[1;32m'
    VERMELHO='\033[1;31m'
    AZUL='\033[1;34m'
    RESET='\033[0m'
else
    VERDE=''; VERMELHO=''; AZUL=''; RESET=''
fi

# --- Lógica Principal --------------------------------------------------------
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

    # Detecta interatividade
    local INTERATIVO=0
    [[ -t 0 ]] && INTERATIVO=1

    # Carrega bibliotecas auxiliares (se existirem)
    if [[ -f "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/log.sh" ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/log.sh"
    fi
    if [[ -f "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/valida.sh" ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/valida.sh"
    fi

    # Loop principal
    while true; do
        mostra_cabecalho
        mostra_menu

        if (( INTERATIVO )); then
            read -rp "Escolha [1-6]: " opcao
        else
            log_aviso "Modo não-interativo detectado. Saindo."
            exit 0
        fi

        case "$opcao" in
            1) opcao_saude ;;
            2) opcao_servico ;;
            3) opcao_logs ;;
            4) opcao_conectividade ;;
            5) opcao_processos ;;
            6) log_info "Saindo..."; exit 0 ;;
            *) log_erro "Opção inválida: $opcao" ;;
        esac

        echo
        if (( INTERATIVO )); then
            read -rp "Pressione Enter para continuar..." _
        fi
        clear
    done

    log_info "fim"
}

main "$@"