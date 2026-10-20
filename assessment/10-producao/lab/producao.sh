#!/usr/bin/env bash
# Lab: Módulo 10 — Scripts de Produção
# Tempo: 25 min | Objetivo: Blindar script frágil → script robusto

# =============================================================================
# ENUNCIADO
# =============================================================================
# O script abaixo FUNCIONA NO LAPTOP mas CAUSA INCIDENTE EM PRODUÇÃO.
# Sua tarefa: reescreva aplicando TODOS conceitos do Módulo 10.

# SCRIPT FRÁGIL (não use em produção):
# #!/usr/bin/env bash
# DIR_ORIGEM=$1
# DIR_DESTINO=$2
# tar -czf $DIR_DESTINO/backup-$(date +%F).tar.gz $DIR_ORIGEM
# echo "Backup concluído em $DIR_DESTINO/backup-$(date +%F).tar.gz"

# REQUISITOS DA SOLUÇÃO (backup-robusto.sh):
# - [ ] set -Eeuo pipefail
# - [ ] Validação de 2 args obrigatórios (origem existe, destino gravável)
# - [ ] Verificação de pré-requisitos (tar, date, gzip)
# - [ ] Opção -n/--dry-run e -v/--verbose
# - [ ] Logging com timestamp, nível, PID
# - [ ] trap EXIT/ERR/INT/TERM com limpeza
# - [ ] flock anti-concorrência (lock file persistente, não /tmp)
# [ ] Arquivo temporário com mktemp + limpeza garantida
# - [ ] Códigos de saída: 0=sucesso, 1=erro, 2=uso, 3=pré-req
# - [ ] shellcheck zero avisos
# - [ ] Idempotente: rodar 2x seguidas não quebra
# - [ ] Nome do backup com timestamp único (evita meia-noite)

# =============================================================================
# SOLUÇÃO COMPLETA
# =============================================================================

set -Eeuo pipefail

# Configurações
readonly SCRIPT_NAME
SCRIPT_NAME="$(basename "$0")"
readonly LOCK_FILE="/var/lock/backup-robusto.lock"
readonly LOG_FILE="/var/log/backup-robusto.log"

# Variáveis de estado
DRY_RUN=0
VERBOSE=0
DIR_ORIGEM=""
DIR_DESTINO=""
TMP_DIR=""

# Logging estruturado
log() {
    local nivel="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo "${timestamp} [${nivel}] [PID:$$] ${msg}" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; } # Usado em traps INT/TERM
log_erro() { log "ERROR" "$@"; }
log_debug() { (( VERBOSE )) && log "DEBUG" "$@"; }

# Execução condicional (dry-run)
run() {
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] $*"
    else
        log_debug "Executando: $*"
        "$@"
    fi
}

# Limpeza garantida (invocado via trap EXIT)
cleanup() {
    local exit_code=$?
    log_debug "Cleanup: removendo diretório temporário $TMP_DIR"
    [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
    # Lock é liberado automaticamente ao fechar FD 9
    exit "$exit_code"
}

# Handlers de sinal
trap cleanup EXIT
trap 'log_erro "Linha $LINENO: $BASH_COMMAND"; exit 1' ERR
trap 'log_warn "Interrompido pelo usuário"; exit 130' INT
trap 'log_warn "Terminado (SIGTERM)"; exit 143' TERM

# Validação de pré-requisitos
valida_comando() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_erro "Comando obrigatório não encontrado: $cmd"
        return 3
    fi
    log_debug "Pré-requisito OK: $cmd"
    return 0
}

valida_diretorio() {
    local dir="$1"
    local tipo="$2"  # origem|destino

    if [[ ! -d "$dir" ]]; then
        log_erro "Diretório $tipo não existe: $dir"
        return 1
    fi

    if [[ "$tipo" == "origem" && ! -r "$dir" ]]; then
        log_erro "Diretório origem sem permissão de leitura: $dir"
        return 1
    fi

    if [[ "$tipo" == "destino" && ! -w "$dir" ]]; then
        log_erro "Diretório destino sem permissão de escrita: $dir"
        return 1
    fi

    log_debug "Diretório $tipo validado: $dir"
    return 0
}

usage() {
    cat <<EOF
${SCRIPT_NAME} - Backup robusto para produção

Uso: ${SCRIPT_NAME} [OPÇÕES] DIR_ORIGEM DIR_DESTINO

Opções:
  -n, --dry-run    Simula execução sem criar backup
  -v, --verbose    Log detalhado (DEBUG)
  -h, --help       Esta ajuda

Códigos de saída:
  0  Sucesso
  1  Erro geral
  2  Uso inválido
  3  Pré-requisitos ausentes

Exemplos:
  ${SCRIPT_NAME} /etc /backup
  ${SCRIPT_NAME} -n /home/user /mnt/backup
  ${SCRIPT_NAME} -v /var/www /backup
EOF
}

# Parse de argumentos
parse_args() {
    local opts
    opts=$(getopt -o nvh --long dry-run,verbose,help -n "$SCRIPT_NAME" -- "$@") || {
        usage >&2
        exit 2
    }
    eval set -- "$opts"

    while true; do
        case $1 in
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            *) log_erro "Opção inválida: $1"; usage >&2; exit 2 ;;
        esac
    done

    DIR_ORIGEM="${1:-}"
    DIR_DESTINO="${2:-}"

    [[ -z "$DIR_ORIGEM" || -z "$DIR_DESTINO" ]] && {
        log_erro "Dois argumentos obrigatórios: DIR_ORIGEM DIR_DESTINO"
        usage >&2
        exit 2
    }
}

# Lock anti-concorrência
adquirir_lock() {
    # Cria diretório do lock se não existe
    local lock_dir
    lock_dir=$(dirname "$LOCK_FILE")
    [[ -d "$lock_dir" ]] || run mkdir -p "$lock_dir"

    # Abre FD 9 no lock file
    exec 9>"$LOCK_FILE"

    # Tenta lock não-bloqueante
    if ! flock -n 9; then
        log_erro "Backup já em andamento (lock: $LOCK_FILE)"
        exit 1
    fi

    log_debug "Lock adquirido: $LOCK_FILE"
}

main() {
    parse_args "$@"

    log_info "=== Iniciando backup robusto ==="
    log_info "Origem: $DIR_ORIGEM | Destino: $DIR_DESTINO"
    (( DRY_RUN )) && log_info "MODO DRY-RUN ativo"

    # Pré-requisitos
    for cmd in tar date gzip; do
        valida_comando "$cmd" || exit 3
    done

    # Validação de diretórios
    valida_diretorio "$DIR_ORIGEM" "origem" || exit 1
    valida_diretorio "$DIR_DESTINO" "destino" || exit 1

    # Lock
    adquirir_lock

    # Diretório temporário
    TMP_DIR=$(mktemp -d -t backup-robusto.XXXXXX)
    log_debug "Diretório temporário: $TMP_DIR"

    # Timestamp único (evita colisão meia-noite)
    local timestamp arquivo_backup
    timestamp=$(date '+%F-%H%M%S')
    arquivo_backup="backup-${timestamp}.tar.gz"
    local destino_completo="${DIR_DESTINO}/${arquivo_backup}"

    log_info "Criando backup: $destino_completo"

    # Executa backup
    run tar -czf "$destino_completo" -C "$DIR_ORIGEM" .

    if (( DRY_RUN )); then
        log_info "[DRY-RUN] Backup simulado: $destino_completo"
    else
        # Verifica integridade
        if run tar -tzf "$destino_completo" >/dev/null; then
            local tamanho
            tamanho=$(stat -c%s "$destino_completo" 2>/dev/null || stat -f%z "$destino_completo")
            log_info "Backup concluído: $destino_completo (${tamanho} bytes)"
        else
            log_erro "Falha na verificação do backup"
            exit 1
        fi
    fi

    log_info "=== Backup finalizado com sucesso ==="
    exit 0
}

main "$@"