#!/usr/bin/env bash
#
# backup-tool.sh - script estruturado para backup com bibliotecas.
#
# Uso: ./backup-tool.sh -o ORIGEM -d DESTINO [-v] [--dry-run] [-h]

set -Eeuo pipefail

readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"

# Importa bibliotecas
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/valida.sh"

ORIGEM=""
DESTINO=""
VERBOSE=0
DRY_RUN=0

uso() {
    cat << EOF
${SCRIPT_NAME} - Ferramenta de backup simples

Uso: ${SCRIPT_NAME} -o ORIGEM -d DESTINO [-v] [--dry-run] [-h]

Opções:
  -o ORIGEM     Arquivo ou diretório de origem (obrigatório)
  -d DESTINO    Diretório de destino (obrigatório)
  -v            Verboso (DEBUG)
  --dry-run     Simula execução sem copiar
  -h            Mostra esta ajuda
EOF
}

valida_entrada() {
    [[ -n "$ORIGEM" ]]  || die "Origem (-o) é obrigatória" 2
    [[ -n "$DESTINO" ]] || die "Destino (-d) é obrigatório" 2

    arquivo_legivel "$ORIGEM" || dir_gravavel "$ORIGEM" || die "Origem '$ORIGEM' não existe ou não é legível" 3
    dir_gravavel "$DESTINO" || die "Destino '$DESTINO' não é diretório gravável" 3
}

executa_backup() {
    local ts
    ts=$(date '+%Y%m%d-%H%M%S')
    local base
    base=$(basename "$ORIGEM")
    local backup
    backup="${DESTINO}/${base}-${ts}"

    if (( DRY_RUN )); then
        log_aviso "[DRY-RUN] Copiaria '$ORIGEM' para '$backup'"
    else
        log_info "Iniciando backup de '$ORIGEM' -> '$backup'"
        if [[ -d "$ORIGEM" ]]; then
            cp -r "$ORIGEM" "$backup"
        else
            cp "$ORIGEM" "$backup"
        fi
        log_sucesso "Backup concluído: $backup"
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o) ORIGEM="${2:-}"; shift 2 ;;
            -d) DESTINO="${2:-}"; shift 2 ;;
            -v) VERBOSE=1; shift ;;
            --dry-run) DRY_RUN=1; shift ;;
            -h|--help) uso; exit 0 ;;
            *) die "Opção desconhecida: $1" 2 ;;
        esac
    done

    (( VERBOSE )) && set -x

    valida_entrada
    executa_backup
}

trap 'log_erro "Interrompido"; exit 130' INT
trap 'log_erro "Erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

main "$@"