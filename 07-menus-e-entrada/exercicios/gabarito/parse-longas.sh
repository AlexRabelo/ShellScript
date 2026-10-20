#!/usr/bin/env bash
#
# parse-longas.sh - parse manual de flags longas (--flag=valor).
#
# Uso: ./parse-longas.sh --host=HOST --porta=PORTA --timeout=SEG [--verbose] [--dry-run] [--help]

set -Eeuo pipefail

HOST=""
PORTA=""
TIMEOUT=30
VERBOSE=0
DRY_RUN=0

uso() {
    cat << EOF
parse-longas.sh - Exemplo de parse de flags longas

Uso: $(basename "$0") --host=HOST --porta=PORTA [--timeout=SEG] [--verbose] [--dry-run] [--help]

Flags:
  --host=HOST       Endereço do host (obrigatório)
  --porta=PORTA     Porta TCP (1-65535)
  --timeout=SEG     Timeout em segundos (padrão: 30)
  --verbose         Modo verboso
  --dry-run         Simula execução
  --help            Esta ajuda
EOF
}

main() {
    # Parse manual de --flag=valor
    for arg in "$@"; do
        case "$arg" in
            --host=*)     HOST="${arg#*=}" ;;
            --porta=*)    PORTA="${arg#*=}" ;;
            --timeout=*)  TIMEOUT="${arg#*=}" ;;
            --verbose)    VERBOSE=1 ;;
            --dry-run)    DRY_RUN=1 ;;
            --help)       uso; exit 0 ;;
            --*)          die "Flag desconhecida: $arg" 2 ;;
            *)            die "Argumento posicional não suportado: $arg" 2 ;;
        esac
    done

    # Validações
    [[ -n "$HOST" ]]  || die "--host é obrigatório" 2
    [[ "$PORTA" =~ ^[0-9]+$ ]] && (( PORTA >= 1 && PORTA <= 65535 )) || die "--porta deve ser 1-65535" 2
    [[ "$TIMEOUT" =~ ^[0-9]+$ ]] && (( TIMEOUT > 0 )) || die "--timeout deve ser > 0" 2

    echo "=== Valores Parseados ==="
    echo "Host:     $HOST"
    echo "Porta:    $PORTA"
    echo "Timeout:  ${TIMEOUT}s"
    echo "Verbose:  $VERBOSE"
    echo "Dry-run:  $DRY_RUN"

    if (( DRY_RUN )); then
        echo "[DRY-RUN] Conectaria em $HOST:$PORTA com timeout ${TIMEOUT}s"
    fi
}

die() {
    echo "ERRO: $1" >&2
    exit "${2:-1}"
}

main "$@"