#!/usr/bin/env bash
#
# cli-backup.sh - interface de linha de comando para backup com opções.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   cli-backup.sh [-o ORIGEM] [-d DESTINO] [-v] [-n] [-h]
#
# Opções:
#   -o ORIGEM   diretório de origem para backup (obrigatório)
#   -d DESTINO  diretório de destino para backup (obrigatório)
#   -v          verbose (mostra detalhes)
#   -n          dry-run (simula sem executar)
#   -h          ajuda
#
# Exemplo:
#   cli-backup.sh -o /etc -d /backup -v
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
# SCRIPT_DIR disponível para scripts que precisam do diretório do script
# readonly SCRIPT_DIR
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
ORIGEM=""
DESTINO=""

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
            -o|--origem) ORIGEM="$2"; shift 2 ;;
            -d|--destino) DESTINO="$2"; shift 2 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    # Validação de argumentos vai aqui
    [[ -z "$ORIGEM" ]] && { usage >&2; die "origem é obrigatória (use -o ORIGEM)" 2; }
    [[ -z "$DESTINO" ]] && { usage >&2; die "destino é obrigatório (use -d DESTINO)" 2; }

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE, origem=$ORIGEM, destino=$DESTINO)"

    # Lógica principal do script vai aqui
    # Exemplo:
    # for arg in "$@"; do
    #     log_info "Processando: $arg"
    # done

    # Valida se os diretórios existem
    [[ -d "$ORIGEM" ]] || die "diretório de origem não existe: $ORIGEM" 1
    [[ -d "$DESTINO" ]] || die "diretório de destino não existe: $DESTINO" 1
    [[ -r "$ORIGEM" ]] || die "sem permissão de leitura no diretório de origem: $ORIGEM" 1
    [[ -w "$DESTINO" ]] || die "sem permissão de escrita no diretório de destino: $DESTINO" 1

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] Fazendo backup de $ORIGEM para $DESTINO"
        log_info "[DRY-RUN] Comando: tar -czf $DESTINO/backup-$(date +%F-%H%M%S).tar.gz -C $(dirname "$ORIGEM") $(basename "$ORIGEM")"
    else
        log_info "Iniciando backup de $ORIGEM para $DESTINO"
        local timestamp
        timestamp=$(date '+%F-%H%M%S')
        local arquivo_backup="${DESTINO}/backup-${timestamp}.tar.gz"

        log_info "Criando backup: $arquivo_backup"
        tar -czf "$arquivo_backup" -C "$(dirname "$ORIGEM")" "$(basename "$ORIGEM")"

        log_info "Backup concluído com sucesso"

        # Gera checksum para verificação
        log_info "Gerando checksum SHA256..."
        sha256sum "$arquivo_backup" > "${arquivo_backup}.sha256"
        log_info "Checksum gerado: $(basename "${arquivo_backup}.sha256")"
    fi

    log_info "fim"
}

main "$@"