#!/usr/bin/env bash
# Lab: Módulo 02 — Variáveis e Parâmetros
# Tempo: 15 min | Objetivo: Criar script que processa argumentos com validação

# =============================================================================
# ENUNCIADO
# =============================================================================
# Crie um script `processa-servidores.sh` que:
# 1. Recebe: AMBIENTE (dev|prod|homolog) + lista de SERVIDORES
# 2. Valida: ambiente válido, pelo menos 1 servidor
# 3. Para cada servidor: simula ping (echo) e mostra status
# 4. Suporte: -v (verbose), -n (dry-run), -h (help)
# 5. Usa array associativo para IPs por ambiente
# 6. Passa em shellcheck sem avisos

# =============================================================================
# SOLUÇÃO COMPLETA
# =============================================================================

set -Eeuo pipefail

# Array associativo: ambiente -> IPs dos servidores
declare -A IPS=(
    ["dev"]="10.0.0.10 10.0.0.11 10.0.0.12"
    ["prod"]="10.1.0.10 10.1.0.11 10.1.0.12 10.1.0.13"
    ["homolog"]="10.2.0.10 10.2.0.11"
)

VERBOSE=0
DRY_RUN=0
AMBIENTE=""
SERVIDORES=()

usage() {
    cat <<'EOF'
processa-servidores - Processa lista de servidores por ambiente

Uso: processa-servidores.sh [-v] [-n] -a AMBIENTE SERVIDOR [SERVIDOR...]

Opções:
  -a AMBIENTE   Ambiente: dev|prod|homolog (obrigatório)
  -v            Verboso
  -n            Dry-run (simula)
  -h            Ajuda

Exemplos:
  processa-servidores.sh -a prod web01 web02 db01
  processa-servidores.sh -n -v -a dev app01
EOF
}

valida_ambiente() {
    local env="$1"
    [[ -n "${IPS[$env]:-}" ]]
}

ping_simulado() {
    local servidor="$1"
    local ip="${IPS[$AMBIENTE]}"

    if (( DRY_RUN )); then
        echo "[DRY-RUN] Ping simulado para $servidor ($ip)"
        return 0
    fi

    if (( VERBOSE )); then
        echo "Verificando $servidor ($ip)..."
    fi

    # Simula: 90% chance de sucesso
    if (( RANDOM % 10 < 9 )); then
        echo "OK: $servidor ($ip) responde"
        return 0
    else
        echo "FALHA: $servidor ($ip) não responde"
        return 1
    fi
}

main() {
    local opt
    while getopts "a:vnh" opt; do
        case $opt in
            a) AMBIENTE="$OPTARG" ;;
            v) VERBOSE=1 ;;
            n) DRY_RUN=1 ;;
            h) usage; exit 0 ;;
            *) usage >&2; exit 2 ;;
        esac
    done
    shift $((OPTIND-1))

    SERVIDORES=("$@")

    # Validações
    if [[ -z "$AMBIENTE" ]]; then
        echo "Erro: ambiente obrigatório (-a)" >&2
        usage >&2
        exit 2
    fi

    if ! valida_ambiente "$AMBIENTE"; then
        echo "Erro: ambiente inválido '$AMBIENTE' (use: dev|prod|homolog)" >&2
        exit 2
    fi

    if (( ${#SERVIDORES[@]} == 0 )); then
        echo "Erro: pelo menos 1 servidor necessário" >&2
        usage >&2
        exit 2
    fi

    (( VERBOSE )) && echo "Ambiente: $AMBIENTE | Servidores: ${SERVIDORES[*]}"
    (( DRY_RUN )) && echo "=== MODO DRY-RUN ==="

    local falhas=0
    for srv in "${SERVIDORES[@]}"; do
        ping_simulado "$srv" || (( falhas++ ))
    done

    echo
    echo "Resumo: ${#SERVIDORES[@]} testados, $falhas falhas"
    (( falhas > 0 )) && exit 1 || exit 0
}

main "$@"