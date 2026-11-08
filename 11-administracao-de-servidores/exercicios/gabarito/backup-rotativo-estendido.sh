#!/usr/bin/env bash
#
# backup-rotativo-estendido.sh - Backup rotativo local/remoto com retenção e verificação
# Estende backup-rotativo.sh com suporte a rsync over SSH para destino remoto.
#
# Uso:
#   backup-rotativo-estendido.sh [-n|--dry-run] [-v|--verbose] [-r|--retencao N]
#                               [-R|--remoto USER@HOST:/caminho] [--apenas-local]
#                               ORIGEM DESTINO_LOCAL
#
# Opções:
#   -n, --dry-run        Simula execução
#   -v, --verbose        Log nível DEBUG
#   -r, --retencao N     Qtd de backups a manter (padrão: 7)
#   -R, --remoto DEST    Destino remoto SSH (user@host:/path)
#   --apenas-local       Força backup local (tar) mesmo com -R
#   -h, --help           Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   backup-rotativo-estendido.sh /dados /backup                    # Local apenas
#   backup-rotativo-estendido.sh -R user@srv:/backup /dados /backup # Local + remoto
#   backup-rotativo-estendido.sh --apenas-local -R user@srv:/bkp /dados /bkp # Só remoto

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
RETENCAO=7
REMOTO_DESTINO=""
APENAS_LOCAL=0
ORIGEM=""
DESTINO_LOCAL=""

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

# --- Limpeza -----------------------------------------------------------------
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
    [[ $codigo -eq 0 ]] || log_erro "terminou com falha (código ${codigo})"
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

# Parse user@host:/path
parse_remoto() {
    local remoto="$1"
    [[ "$remoto" =~ ^([^@]+)@([^:]+):(.+)$ ]] || die "formato remoto inválido: $remoto (use user@host:/path)" 2
    REMOTO_USER="${BASH_REMATCH[1]}"
    REMOTO_HOST="${BASH_REMATCH[2]}"
    REMOTO_PATH="${BASH_REMATCH[3]}"
}

# Lista backups locais
listar_backups_locais() {
    find "$DESTINO_LOCAL" -maxdepth 1 -name "backup-*.tar.gz" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | cut -d' ' -f2-
}

# Lista backups remotos
listar_backups_remotos() {
    local cmd="find '$REMOTO_PATH' -maxdepth 1 -name 'backup-*.tar.gz' -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | cut -d' ' -f2-"
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$REMOTO_USER@$REMOTO_HOST" "$cmd" 2>/dev/null || true
}

# Aplica retenção local
aplicar_retencao_local() {
    local backups
    mapfile -t backups < <(listar_backups_locais)
    local total=${#backups[@]}

    if (( total <= RETENCAO )); then
        log_debug "Retenção local ok: $total backups (limite: $RETENCAO)"
        return 0
    fi

    local remover=$(( total - RETENCAO ))
    log_info "Retenção local: removendo $remover de $total backups antigos"

    for ((i=0; i<remover; i++)); do
        local antigo="${backups[i]}"
        log_dry "Removendo backup local antigo: $antigo"
        run rm -f -- "$antigo" "${antigo}.sha256"
    done
}

# Aplica retenção remota
aplicar_retencao_remota() {
    [[ -z "$REMOTO_DESTINO" ]] && return 0

    local backups
    mapfile -t backups < <(listar_backups_remotos)
    local total=${#backups[@]}

    if (( total <= RETENCAO )); then
        log_debug "Retenção remota ok: $total backups (limite: $RETENCAO)"
        return 0
    fi

    local remover=$(( total - RETENCAO ))
    log_info "Retenção remota: removendo $remover de $total backups antigos"

    for ((i=0; i<remover; i++)); do
        local antigo="${backups[i]}"
        log_dry "Removendo backup remoto antigo: $antigo"
        run ssh -o BatchMode=yes "$REMOTO_USER@$REMOTO_HOST" "rm -f -- '$antigo' '${antigo}.sha256'"
    done
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -r|--retencao) RETENCAO="${2:-}"; shift 2 ;;
            -R|--remoto) REMOTO_DESTINO="${2:-}"; shift 2 ;;
            --apenas-local) APENAS_LOCAL=1; shift ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    [[ "$RETENCAO" =~ ^[0-9]+$ ]] && (( RETENCAO > 0 )) || die "retenção deve ser número positivo: $RETENCAO" 2

    [[ $# -eq 2 ]] || { usage >&2; die "informe exatamente 2 argumentos: ORIGEM DESTINO_LOCAL" 2; }
    ORIGEM="$1"
    DESTINO_LOCAL="$2"

    # Pré-requisitos
    requer_comando tar
    requer_comando date
    requer_comando mktemp
    requer_comando flock
    requer_comando find
    requer_comando sha256sum
    requer_comando mkdir
    [[ -n "$REMOTO_DESTINO" ]] && { requer_comando rsync; requer_comando ssh; parse_remoto "$REMOTO_DESTINO"; }

    validar_diretorio "$ORIGEM" "origem"
    validar_diretorio "$DESTINO_LOCAL" "destino local"

    # Lock file inclui host remoto se aplicável
    local lock_suffix=""
    [[ -n "$REMOTO_DESTINO" ]] && lock_suffix="-${REMOTO_HOST//\./-}"
    readonly LOCK_FILE="/var/lock/${SCRIPT_NAME%.sh}${lock_suffix}.lock"

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
    ARQUIVO_BACKUP="${DESTINO_LOCAL}/backup-${timestamp}.tar.gz"

    log_info "início (origem=$ORIGEM, destino_local=$DESTINO_LOCAL, remoto=${REMOTO_DESTINO:-não}, retenção=$RETENCAO, dry-run=$DRY_RUN)"

    # --- BACKUP LOCAL ---
    if [[ "$APENAS_LOCAL" -eq 0 || -z "$REMOTO_DESTINO" ]]; then
        log_info "Criando backup local (tar): $ARQUIVO_BACKUP"
        run tar -czf "$ARQUIVO_BACKUP" -C "$(dirname "$ORIGEM")" "$(basename "$ORIGEM")"

        if [[ "$DRY_RUN" -eq 0 ]]; then
            log_info "Gerando checksum SHA256..."
            run sha256sum "$ARQUIVO_BACKUP" > "${ARQUIVO_BACKUP}.sha256" 2>/dev/null

            local tamanho
            tamanho=$(du -h "$ARQUIVO_BACKUP" | cut -f1)
            log_info "Backup local criado: $ARQUIVO_BACKUP ($tamanho)"

            log_info "Verificando integridade local..."
            run sha256sum -c "${ARQUIVO_BACKUP}.sha256" > /dev/null
            log_info "Checksum local OK"
        fi
    fi

    # --- BACKUP REMOTO (rsync) ---
    if [[ -n "$REMOTO_DESTINO" ]]; then
        local remoto_destino_final="${REMOTO_USER}@${REMOTO_HOST}:${REMOTO_PATH}"
        log_info "Sincronizando com destino remoto: $remoto_destino_final"

        # rsync options
        local rsync_opts=(-az --delete)
        [[ "$DRY_RUN" -eq 1 ]] && rsync_opts+=(--dry-run)

        run rsync "${rsync_opts[@]}" "$ORIGEM/" "$remoto_destino_final/"

        if [[ "$DRY_RUN" -eq 0 ]]; then
            # Verifica integridade remota
            log_info "Verificando integridade remota..."
            run ssh -o BatchMode=yes "$REMOTO_USER@$REMOTO_HOST" \
                "cd '$REMOTO_PATH' && sha256sum -c backup-${timestamp}.tar.gz.sha256" 2>/dev/null || true
            log_info "Verificação remota concluída"
        fi
    fi

    # --- RETENÇÃO ---
    log_info "Aplicando política de retenção (manter $RETENCAO)..."
    aplicar_retencao_local
    aplicar_retencao_remota

    # Lista final
    if [[ "$DRY_RUN" -eq 0 ]]; then
        log_info "Backups locais atuais:"
        local backups_locais
        mapfile -t backups_locais < <(listar_backups_locais)
        for bkp in "${backups_locais[@]}"; do
            local tam data
            tam=$(du -h "$bkp" | cut -f1)
            data=$(stat -c '%y' "$bkp" 2>/dev/null | cut -d. -f1 || date -r "$bkp" '+%F %T' 2>/dev/null)
            log_info "  $(basename "$bkp") - $tam - $data"
        done

        if [[ -n "$REMOTO_DESTINO" ]]; then
            log_info "Backups remotos atuais:"
            local backups_remotos
            mapfile -t backups_remotos < <(listar_backups_remotos)
            for bkp in "${backups_remotos[@]}"; do
                log_info "  $(basename "$bkp")"
            done
        fi
    fi
}

main "$@"