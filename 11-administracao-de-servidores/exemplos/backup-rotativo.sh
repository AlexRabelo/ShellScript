#!/usr/bin/env bash
#
# backup-rotativo.sh - Backup rotativo com retenção, checksum e dry-run
# Cria backup tar.gz, mantém N últimos, verifica integridade, remove antigos.
# Baseado no template de produção (módulo 10).
#
# Uso:
#   backup-rotativo.sh [-n|--dry-run] [-v|--verbose] [-r|--retencao N] ORIGEM DESTINO
#
# Opções:
#   -n, --dry-run       Simula execução sem criar/remover arquivos
#   -v, --verbose       Log nível DEBUG
#   -r, --retencao N    Quantidade de backups a manter (padrão: 7)
#   -h, --help          Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro genérico | 2 uso incorreto | 3 pré-requisito ausente
#
# Exemplos:
#   backup-rotativo.sh /etc /backup                    # 7 dias retenção
#   backup-rotativo.sh -r 30 /dados /backup            # 30 dias retenção
#   backup-rotativo.sh -n -v /etc /backup              # Simula com debug
#   backup-rotativo.sh --retencao 14 /var/www /mnt/backup

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"
readonly LOCK_FILE="/var/lock/${SCRIPT_NAME%.sh}.lock"

DRY_RUN=0
VERBOSE=0
RETENCAO=7
ORIGEM=""
DESTINO=""

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local prefixo=""
    [[ "$nivel" == "DRY-RUN" ]] && prefixo="[SIMULAÇÃO] "
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: ${prefixo}$*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      if [[ "$VERBOSE" -eq 1 ]]; then printf '%s\n' "$msg"; fi ;;
        DRY-RUN)    printf '%s\n' "$msg" ;;
        *)          printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }
log_dry()   { log "DRY-RUN" "$@"; }

die() {
    local codigo="${2:-1}"
    log_erro "$1"
    exit "$codigo"
}

# --- Limpeza e traps ---------------------------------------------------------
TMP_DIR=""
ARQUIVO_BACKUP=""
LOCK_FD=9

cleanup() {
    local codigo=$?
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        log_debug "Removendo diretório temporário: $TMP_DIR"
        rm -rf -- "$TMP_DIR"
    fi
    if [[ -n "$ARQUIVO_BACKUP" && -f "$ARQUIVO_BACKUP" && "$codigo" -ne 0 && "$DRY_RUN" -eq 0 ]]; then
        log_aviso "Removendo backup parcial: $ARQUIVO_BACKUP"
        rm -f -- "$ARQUIVO_BACKUP" "${ARQUIVO_BACKUP}.sha256"
    fi
    if [[ -n "${LOCK_FD:-}" ]]; then
        eval "exec ${LOCK_FD}>&-"
    fi
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
run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_dry "$*"
        return 0
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

# Lista backups existentes ordenados por data (mais antigo primeiro)
listar_backups_existentes() {
    find "$DESTINO" -maxdepth 1 -name "backup-*.tar.gz" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | cut -d' ' -f2-
}

# Remove backups excedentes (mantém os $RETENCAO mais recentes)
aplicar_retencao() {
    local backups
    mapfile -t backups < <(listar_backups_existentes)
    local total=${#backups[@]}

    if (( total <= RETENCAO )); then
        log_debug "Retenção ok: $total backups (limite: $RETENCAO)"
        return 0
    fi

    local remover=$(( total - RETENCAO ))
    log_info "Aplicando retenção: $total backups encontrados, removendo $remover mais antigos"

    for ((i=0; i<remover; i++)); do
        local antigo="${backups[i]}"
        local checksum="${antigo}.sha256"
        log_dry "Removendo backup antigo: $antigo"
        run rm -f -- "$antigo" "$checksum"
    done
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

# --- Lógica principal --------------------------------------------------------
main() {
    # Parse de opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -r|--retencao) RETENCAO="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

# Valida retenção
    if [[ "$RETENCAO" =~ ^[0-9]+$ ]] && (( RETENCAO > 0 )); then
        :
    else
        die "retenção deve ser número positivo: $RETENCAO" 2
    fi
    # Argumentos posicionais
    [[ $# -eq 2 ]] || { usage >&2; die "informe exatamente 2 argumentos: ORIGEM DESTINO" 2; }
    ORIGEM="$1"
    DESTINO="$2"

    # Pré-requisitos
    requer_comando tar
    requer_comando date
    requer_comando mktemp
    requer_comando flock
    requer_comando find
    requer_comando sha256sum
    requer_comando mkdir

    validar_diretorio "$ORIGEM" "origem"
    validar_diretorio "$DESTINO" "destino"

    # Lock exclusivo
    exec {LOCK_FD}> "$LOCK_FILE"
    if ! flock -n "$LOCK_FD"; then
        local pid_atual
        pid_atual=$(cat "$LOCK_FILE" 2>/dev/null || echo "desconhecido")
        die "já existe backup em andamento (PID: $pid_atual)" 1
    fi
    echo "$$" >&"$LOCK_FD"

    # Preparação
    TMP_DIR="$(mktemp -d -t "${SCRIPT_NAME%.sh}.XXXXXX")"
    local timestamp
    timestamp="$(date '+%F-%H%M%S')"
    ARQUIVO_BACKUP="${DESTINO}/backup-${timestamp}.tar.gz"

    log_info "início (origem=$ORIGEM, destino=$DESTINO, retenção=$RETENCAO, dry-run=$DRY_RUN)"

    # Cria backup
    log_info "Criando backup: $ARQUIVO_BACKUP"
    run tar -czf "$ARQUIVO_BACKUP" -C "$(dirname "$ORIGEM")" "$(basename "$ORIGEM")"

    # Verificação de integridade
    if [[ "$DRY_RUN" -eq 0 ]]; then
        log_info "Gerando checksum SHA256..."
        run sha256sum "$ARQUIVO_BACKUP" > "${ARQUIVO_BACKUP}.sha256" 2>/dev/null

        local tamanho
        tamanho=$(du -h "$ARQUIVO_BACKUP" | cut -f1)
        log_info "Backup criado: $ARQUIVO_BACKUP ($tamanho)"

        # Verifica checksum imediatamente
        log_info "Verificando integridade..."
        run sha256sum -c "${ARQUIVO_BACKUP}.sha256" > /dev/null
        log_info "Checksum OK"
    fi

    # Aplica retenção (após criar novo para não ficar sem backup se falhar)
    log_info "Aplicando política de retenção (manter $RETENCAO)..."
    aplicar_retencao

    # Lista final
    if [[ "$DRY_RUN" -eq 0 ]]; then
        local backups_finais
        mapfile -t backups_finais < <(listar_backups_existentes)
        log_info "Backups atuais (${#backups_finais[@]}):"
        for bkp in "${backups_finais[@]}"; do
            local tam data
            tam=$(du -h "$bkp" | cut -f1)
            data=$(stat -c '%y' "$bkp" | cut -d. -f1)
            log_info "  $(basename "$bkp") - $tam - $data"
        done
    fi
}

main "$@"