#!/usr/bin/env bash
# =============================================================================
# inventario-servidores.sh — Gabarito de arrays associativos e expansões
# =============================================================================
# Autor: Alex Rabelo
# Versão: 1.0.0
# Descrição: Armazena servidores em array associativo e normaliza caminhos sem
#            depender de comandos externos (basename/dirname).
# Uso: ./inventario-servidores.sh [--help]
# Códigos de saída: 0 sucesso
# =============================================================================

set -Eeuo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Uso: ${0##*/} [--help]"
    exit 0
fi

declare -A inventario=(
    ["web-01"]="10.0.1.11"
    ["db-01"]="10.0.2.21"
    ["cache-01"]="10.0.3.31"
)

echo "Total de hosts: ${#inventario[@]}"
for host in "${!inventario[@]}"; do
    printf '%-12s -> %s\n' "$host" "${inventario[$host]}"
done

arquivo="/opt/backups/db-prod-2026.tar.gz"
echo "Nome: ${arquivo##*/}"
echo "Pasta: ${arquivo%/*}"
echo "Sem .gz: ${arquivo%.gz}"
echo "Sem .tar.gz: ${arquivo%.tar.gz}"
