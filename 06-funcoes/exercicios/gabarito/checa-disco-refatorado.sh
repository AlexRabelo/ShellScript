#!/usr/bin/env bash
#
# checa-disco-refatorado.sh - versão refatorada usando lib/disco.sh.
#
# Uso: ./checa-disco-refatorado.sh [PONTO_MONTAGEM] [AVISO] [CRITICO]

set -Eeuo pipefail

readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/disco.sh"

PONTO="${1:-/}"
AVISO="${2:-80}"
CRITICO="${3:-90}"

verifica_disco "$PONTO" "$AVISO" "$CRITICO"
exit $?