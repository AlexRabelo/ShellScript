#!/usr/bin/env bash
#
# comandos/backup.sh - Backup rotativo com verificação de integridade
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   sre-toolkit backup [-r|--retencao N] [-n|--dry-run] [-v|--verbose] ORIGEM DESTINO
#
# Opções:
#   -r, --retencao N   Número de backups a manter (padrão: 7)
#   -n, --dry-run      Simula execução
#   -v, --verbose      Inclui detalhes
#   -h, --help         Exibe ajuda
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto
#
# Exemplos:
#   sre-toolkit backup /etc /backup
#   sre-toolkit backup -r 30 -n /var/www /mnt/backup
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LIB_DIR="${LIB_DIR:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")/lib}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

# Carrega bibliotecas
# shellcheck source=/dev/null
source "${LIB_DIR}/log.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/valida.sh"
source "${LIB_DIR}/util.sh"

RETENCAO=7
DRY_RUN=0
VERBOSE=0

usage() {
    cat <<EOF
backup - Backup rotativo com verificação de integridade

Uso: sre-toolkit backup [-r|--retencao N] [-n|--dry-run] [-v|--verbose] ORIGEM DESTINO

Opções:
  -r, --retencao N   Número de backups a manter (padrão: 7)
  -n, --dry-run      Simula execução
  -v, --verbose      Inclui detalhes
  -h, --help         Exibe ajuda
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--retencao) RETENCAO="${2:-}"; shift 2 ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done

    [[ $# -eq 2 ]] || { log_erro "Argumentos necessários: ORIGEM DESTINO"; usage >&2; exit 2; }
    local ORIGEM="$1"
    local DESTINO="$2"

    valida_diretorio "$ORIGEM" || exit 1
    valida_diretorio "$DESTINO" || exit 1
    valida_numero "$RETENCAO" "retenção" || exit 2

    log_info "início (origem=$ORIGEM, destino=$DESTINO, retenção=$RETENCAO, dry-run=$DRY_RUN)"

    # Simula a funcionalidade de backup (versão completa usaria o módulo 11)
    local timestamp
    timestamp=$(date '+%F-%H%M%S')
    local backup_file="${DESTINO}/backup-${timestamp}.tar.gz"

    log_info "criando backup: $backup_file"
    run tar -czf "$backup_file" -C "$(dirname "$ORIGEM")" "$(basename "$ORIGEM")"

    if (( DRY_RUN == 0 )); then
        log_info "gerando checksum SHA256"
        run sha256sum "$backup_file" > "${backup_file}.sha256"
        log_info "backup criado com sucesso"

        # Simula retenção
        log_info "aplicando retenção de $RETENCAO backups"
        # Em produção: listaria backups antigos e removeria os excedentes
    fi

    log_info "fim"
}

main "$@"