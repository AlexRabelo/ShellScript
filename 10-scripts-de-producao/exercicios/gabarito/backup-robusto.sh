#!/usr/bin/env bash
#
# backup-robusto.sh - Backup robusto para produção
# Aplica: modo estrito, trap, lock, dry-run, logging, validações
#
# Uso:
#   backup-robusto.sh [-n] [-v] [-h] DIR_ORIGEM DIR_DESTINO
#
# Opções:
#   -n, --dry-run    Simula execução sem alterar nada
#   -v, --verbose    Log nível DEBUG
#   -h, --help       Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro genérico | 2 uso incorreto | 3 pré-requisito ausente

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/var/log/${SCRIPT_NAME%.sh}.log}"
readonly LOCK_FILE="/var/lock/${SCRIPT_NAME%.sh}.lock"

DRY_RUN=0
VERBOSE=0
TMP_DIR=""
ARQUIVO_BACKUP=""

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$msg" ;;
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

# --- Limpeza e traps ---------------------------------------------------------
cleanup() {
    local codigo=$?
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        log_debug "Removendo diretório temporário: $TMP_DIR"
        rm -rf -- "$TMP_DIR"
    fi
    if [[ -n "$ARQUIVO_BACKUP" && -f "$ARQUIVO_BACKUP" && "$codigo" -ne 0 ]]; then
        log_aviso "Removendo backup parcial: $ARQUIVO_BACKUP"
        rm -f -- "$ARQUIVO_BACKUP"
    fi
    if [[ "$codigo" -ne 0 ]]; then
        log_erro "terminou com falha (código ${codigo})"
    else
        log_info "terminou com sucesso"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Utilidades --------------------------------------------------------------
run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[dry-run] $*"
    else
        log_debug "executando: $*"
        "$@"
    fi
}

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

validar_diretorio() {
    local path="$1" tipo="$2"
    [[ -d "$path" ]] || die "diretório $tipo não existe: $path" 1
    [[ -r "$path" ]] || die "sem permissão de leitura no diretório $tipo: $path" 1
    [[ -w "$path" ]] || die "sem permissão de escrita no diretório $tipo: $path" 1
}

# --- Lógica principal --------------------------------------------------------
main() {
    local dir_origem="" dir_destino=""

    # Parse de opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    # Argumentos posicionais
    [[ $# -eq 2 ]] || { usage >&2; die "informe exatamente 2 argumentos: ORIGEM DESTINO" 2; }
    dir_origem="$1"
    dir_destino="$2"

    # Pré-requisitos
    requer_comando tar
    requer_comando date
    requer_comando mktemp
    requer_comando flock
    requer_comando mkdir

    validar_diretorio "$dir_origem" "origem"
    validar_diretorio "$dir_destino" "destino"

    # Lock exclusivo
    exec 9> "$LOCK_FILE"
    if ! flock -n 9; then
        local pid_atual
        pid_atual=$(cat "$LOCK_FILE" 2>/dev/null || echo "desconhecido")
        die "já existe backup em andamento (PID: $pid_atual)" 1
    fi
    echo "$$" >&9

    # Preparação
    TMP_DIR="$(mktemp -d -t "${SCRIPT_NAME%.sh}.XXXXXX")"
    local timestamp
    timestamp="$(date '+%F-%H%M%S')"
    ARQUIVO_BACKUP="${dir_destino}/backup-${timestamp}.tar.gz"

    log_info "início (origem=$dir_origem, destino=$dir_destino, dry-run=$DRY_RUN)"

    # Execução do backup
    run tar -czf "$ARQUIVO_BACKUP" -C "$(dirname "$dir_origem")" "$(basename "$dir_origem")"

    # Verificação de integridade (apenas se não dry-run)
    if [[ "$DRY_RUN" -eq 0 ]]; then
        run sha256sum "$ARQUIVO_BACKUP" > "${ARQUIVO_BACKUP}.sha256"
        local tamanho
        tamanho=$(du -h "$ARQUIVO_BACKUP" | cut -f1)
        log_info "backup criado: $ARQUIVO_BACKUP ($tamanho)"
    fi
}

main "$@"