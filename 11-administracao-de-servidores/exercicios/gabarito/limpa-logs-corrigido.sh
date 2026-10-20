#!/usr/bin/env bash
#
# limpa-logs-corrigido.sh - Limpeza segura de logs antigos (versão corrigida)
# Remove arquivos .log com mais de N dias, com validações e dry-run.
#
# Uso:
#   limpa-logs-corrigido.sh [-n|--dry-run] [-v|--verbose] [-d|--dias N]
#                          [-p|--padrao GLOB] DIRETORIO
#
# Opções:
#   -n, --dry-run       Simula execução
#   -v, --verbose       Log nível DEBUG
#   -d, --dias N        Idade mínima em dias (padrão: 30)
#   -p, --padrao GLOB   Padrão de arquivos (padrão: *.log)
#   -h, --help          Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 erro | 2 uso incorreto | 3 pré-requisito

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
DIAS=30
PADRAO="*.log"
DIRETORIO=""

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
cleanup() {
    local codigo=$?
    [[ $codigo -eq 0 ]] || log_erro "terminou com falha (código ${codigo})"
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades --------------------------------------------------------------
requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

validar_diretorio() {
    local path="$1"
    [[ -d "$path" ]] || die "diretório não existe: $path" 1
    [[ -r "$path" ]] || die "sem permissão de leitura: $path" 1
    [[ -w "$path" ]] || die "sem permissão de escrita: $path" 1
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,19p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -d|--dias) DIAS="${2:-}"; shift 2 ;;
            -p|--padrao) PADRAO="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    [[ "$DIAS" =~ ^[0-9]+$ ]] && (( DIAS >= 0 )) || die "dias deve ser número não-negativo: $DIAS" 2

    [[ $# -eq 1 ]] || { usage >&2; die "informe exatamente 1 argumento: DIRETORIO" 2; }
    DIRETORIO="$1"

    # Pré-requisitos
    requer_comando find
    requer_comando du
    validar_diretorio "$DIRETORIO"

    log_info "início (dir=$DIRETORIO, padrao=$PADRAO, dias=$DIAS, dry-run=$DRY_RUN)"

    # Busca arquivos (usando find com -print0 para segurança com nomes estranhos)
    local arquivos=()
    while IFS= read -r -d '' arquivo; do
        arquivos+=("$arquivo")
    done < <(find "$DIRETORIO" -maxdepth 1 -type f -name "$PADRAO" -mtime +"$DIAS" -print0 2>/dev/null)

    if [[ ${#arquivos[@]} -eq 0 ]]; then
        log_info "Nenhum arquivo encontrado para limpeza (padrão: $PADRAO, >${DIAS} dias)"
        exit 0
    fi

    log_info "Encontrados ${#arquivos[@]} arquivo(s) para remoção:"

    local total_bytes=0
    for arq in "${arquivos[@]}"; do
        local tamanho_bytes tamanho_humano
        tamanho_bytes=$(stat -c%s "$arq" 2>/dev/null || echo 0)
        total_bytes=$(( total_bytes + tamanho_bytes ))

        if [[ $tamanho_bytes -ge 1073741824 ]]; then
            tamanho_humano="$(( tamanho_bytes / 1073741824 )) GB"
        elif [[ $tamanho_bytes -ge 1048576 ]]; then
            tamanho_humano="$(( tamanho_bytes / 1048576 )) MB"
        elif [[ $tamanho_bytes -ge 1024 ]]; then
            tamanho_humano="$(( tamanho_bytes / 1024 )) KB"
        else
            tamanho_humano="${tamanho_bytes} B"
        fi

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_dry "Removendo: $arq ($tamanho_humano)"
        else
            log_info "Removendo: $arq ($tamanho_humano)"
            rm -f -- "$arq"
        fi
    done

    # Total humano
    local total_humano
    if [[ $total_bytes -ge 1073741824 ]]; then
        total_humano="$(( total_bytes / 1073741824 )) GB"
    elif [[ $total_bytes -ge 1048576 ]]; then
        total_humano="$(( total_bytes / 1048576 )) MB"
    elif [[ $total_bytes -ge 1024 ]]; then
        total_humano="$(( total_bytes / 1024 )) KB"
    else
        total_humano="${total_bytes} B"
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "Total que seria liberado: $total_humano"
    else
        log_info "Limpeza concluída. Espaço liberado: $total_humano"
    fi
}

main "$@"