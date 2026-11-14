#!/usr/bin/env bash
# =============================================================================
# arrays-e-expansoes.sh — Demonstra arrays indexados, associativos e expansões
# =============================================================================
# Autor: Alex Rabelo
# Versão: 1.0.0
# Descrição: Exemplo prático de inventário de serviços e normalização de paths
#            usando apenas recursos nativos do Bash 4+.
# Uso: ./arrays-e-expansoes.sh [--help]
# Códigos de saída: 0 sucesso | 2 uso incorreto
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"

uso() {
    cat <<EOF
Uso: ${SCRIPT_NAME} [--help]

Demonstra arrays indexados, arrays associativos e expansões de parâmetros.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    uso
    exit 0
fi

if [[ $# -gt 0 ]]; then
    echo "Erro: argumento desconhecido '$1'" >&2
    uso >&2
    exit 2
fi

# 1. Array indexado com regiões AWS
regioes=("us-east-1" "sa-east-1" "eu-west-1")
echo "=== Regiões configuradas (${#regioes[@]}) ==="
for regiao in "${regioes[@]}"; do
    echo "- ${regiao}"
done

# 2. Array associativo (chave -> porta)
declare -A servicos=(
    ["nginx"]="443"
    ["postgres"]="5432"
    ["prometheus"]="9090"
)

echo ""
echo "=== Mapa de serviços ==="
for svc in "${!servicos[@]}"; do
    echo "${svc} -> porta ${servicos[$svc]}"
done

# 3. Expansões de parâmetros sem subshell
caminho_log="/var/log/nginx/access.2026.log"
ambiente="${AMBIENTE_ALVO:-homologacao}"

echo ""
echo "=== Expansões de parâmetros ==="
echo "Ambiente: ${ambiente}"
echo "Arquivo: ${caminho_log##*/}"
echo "Diretório: ${caminho_log%/*}"
echo "Sem extensão: ${caminho_log%.log}"
echo "Hífens por underscores: ${regioes[1]//-/_}"
