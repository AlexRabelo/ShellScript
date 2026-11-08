#!/usr/bin/env bash
#
# carrega-libs.sh - demonstra importação dinâmica de bibliotecas.
#
# Uso: ./carrega-libs.sh

set -Eeuo pipefail

# Função para carregar biblioteca procurando em múltiplos locais
carrega_biblioteca() {
    local nome="$1"
    local caminhos=(
        "${SCRIPT_DIR}/lib/${nome}.sh"
        "/usr/local/lib/${nome}.sh"
        "/opt/lib/${nome}.sh"
    )

    for caminho in "${caminhos[@]}"; do
        if [[ -f "$caminho" ]]; then
            # shellcheck source=/dev/null
            source "$caminho"
            return 0
        fi
    done

    die "Biblioteca '$nome' não encontrada em: ${caminhos[*]}" 1
}

readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Demonstra carregamento
carrega_biblioteca "log"
carrega_biblioteca "valida"

log_info "Bibliotecas carregadas com sucesso!"
log_sucesso "Teste de log_sucesso"
log_aviso "Teste de log_aviso"

# Teste de validação
if eh_ip "192.168.1.1"; then
    log_info "192.168.1.1 é IP válido"
fi

if eh_porta 8080; then
    log_info "8080 é porta válida"
fi