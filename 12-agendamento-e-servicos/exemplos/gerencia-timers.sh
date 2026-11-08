#!/usr/bin/env bash
#
# gerencia-timers.sh - Gerencia systemd timers e serviços relacionados
# Instala, habilita, mostra status, logs e próximas execuções.
#
# Uso:
#   gerencia-timers.sh <comando> [opções]
#
# Comandos:
#   instalar          Copia .service/.timer para /etc/systemd/system/ e recarrega
#   habilitar         Habilita e inicia o timer (enable --now)
#   desabilitar       Para e desabilita o timer (disable --now)
#   status            Mostra status do timer e serviço
#   logs              Mostra logs do serviço (journalctl -f)
#   logs-timer        Mostra logs do timer
#   proximas          Lista próximas execuções de todos os timers
#   executar          Força execução imediata do serviço
#   listar            Lista todos os timers instalados
#
# Opções:
#   -s, --servico NOME    Nome base do serviço/timer (padrão: backup-diario)
#   -d, --diretorio DIR   Diretório com arquivos .service/.timer (padrão: exemplos/)
#   -n, --linhas N        Linhas de log para mostrar (padrão: 50)
#   -h, --help            Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito (root/systemd)

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

SERVICO_BASE="backup-diario"
DIR_EXEMPLOS="exemplos"
LINHAS_LOG=50
COMANDO=""

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      printf '%s\n' "$msg" >&2 ;;
        *)          printf '%s\n' "$msg" ;;
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

# --- Verificações ------------------------------------------------------------
requer_root() {
    [[ $EUID -eq 0 ]] || die "este comando requer root (use sudo)" 3
}

requer_systemd() {
    command -v systemctl > /dev/null 2>&1 || die "systemd não encontrado" 3
    [[ -d /run/systemd/system ]] || die "systemd não está rodando" 3
}

verificar_arquivos() {
    local dir="$1"
    local base="$2"
    [[ -f "$dir/$base.service" ]] || die "arquivo não encontrado: $dir/$base.service" 1
    [[ -f "$dir/$base.timer" ]] || die "arquivo não encontrado: $dir/$base.timer" 1
}

# --- Comandos ----------------------------------------------------------------
cmd_instalar() {
    requer_root
    requer_systemd
    verificar_arquivos "$DIR_EXEMPLOS" "$SERVICO_BASE"

    log_info "Instalando $SERVICO_BASE.service e $SERVICO_BASE.timer em /etc/systemd/system/"
    cp "$DIR_EXEMPLOS/$SERVICO_BASE.service" "$DIR_EXEMPLOS/$SERVICO_BASE.timer" /etc/systemd/system/
    systemctl daemon-reload
    log_info "Instalação concluída. Use 'habilitar' para ativar."
}

cmd_habilitar() {
    requer_root
    requer_systemd
    log_info "Habilitando e iniciando timer: $SERVICO_BASE.timer"
    systemctl enable --now "$SERVICO_BASE.timer"
    log_info "Timer ativado. Próxima execução:"
    systemctl list-timers --all | grep "$SERVICO_BASE" || true
}

cmd_desabilitar() {
    requer_root
    requer_systemd
    log_info "Parando e desabilitando timer: $SERVICO_BASE.timer"
    systemctl disable --now "$SERVICO_BASE.timer"
    log_info "Timer desabilitado."
}

cmd_status() {
    requer_systemd
    log_info "Status do timer: $SERVICO_BASE.timer"
    systemctl status "$SERVICO_BASE.timer" --no-pager || true
    echo
    log_info "Status do serviço: $SERVICO_BASE.service"
    systemctl status "$SERVICO_BASE.service" --no-pager || true
}

cmd_logs() {
    requer_systemd
    log_info "Logs do serviço (últimas $LINHAS_LOG linhas, -f para seguir):"
    journalctl -u "$SERVICO_BASE.service" -n "$LINHAS_LOG" --no-pager
}

cmd_logs_timer() {
    requer_systemd
    log_info "Logs do timer (últimas $LINHAS_LOG linhas):"
    journalctl -u "$SERVICO_BASE.timer" -n "$LINHAS_LOG" --no-pager
}

cmd_proximas() {
    requer_systemd
    log_info "Próximas execuções de todos os timers:"
    systemctl list-timers --all --no-pager
}

cmd_executar() {
    requer_root
    requer_systemd
    log_info "Forçando execução imediata de: $SERVICO_BASE.service"
    systemctl start "$SERVICO_BASE.service"
    log_info "Execução iniciada. Acompanhe com: $0 logs"
}

cmd_listar() {
    requer_systemd
    log_info "Timers instalados no sistema:"
    systemctl list-unit-files --type=timer --state=enabled,disabled,static --no-pager | grep -v '^UNIT FILE' | head -30
    echo
    log_info "Timers ativos (carregados):"
    systemctl list-timers --all --no-pager | head -30
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,27p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Main --------------------------------------------------------------------
main() {
    # Parse comando (primeiro argumento não-opção)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--servico) SERVICO_BASE="${2:-}"; shift 2 ;;
            -d|--diretorio) DIR_EXEMPLOS="${2:-}"; shift 2 ;;
            -n|--linhas) LINHAS_LOG="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *)
                if [[ -z "$COMANDO" ]]; then
                    COMANDO="$1"
                else
                    die "argumento extra: $1" 2
                fi
                shift
                ;;
        esac
    done

    [[ -n "$COMANDO" ]] || { usage >&2; die "comando obrigatório" 2; }

    case "$COMANDO" in
        instalar) cmd_instalar ;;
        habilitar) cmd_habilitar ;;
        desabilitar) cmd_desabilitar ;;
        status) cmd_status ;;
        logs) cmd_logs ;;
        logs-timer) cmd_logs_timer ;;
        proximas) cmd_proximas ;;
        executar) cmd_executar ;;
        listar) cmd_listar ;;
        *) die "comando desconhecido: $COMANDO" 2 ;;
    esac
}

main "$@"