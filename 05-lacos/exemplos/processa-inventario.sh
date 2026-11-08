#!/usr/bin/env bash
#
# processa-inventario.sh - Lê inventário de servidores (CSV) linha a linha
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   processa-inventario.sh [ARQUIVO_CSV]
#
# Argumentos:
#   ARQUIVO_CSV   Arquivo CSV com formato: HOST,IP,AMBIENTE,SO (opcional, padrão: /tmp/inventario.csv)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto
#
# Exemplos:
#   ./processa-inventario.sh
#   ./processa-inventario.sh /caminho/para/inventario.csv
#
# Demonstra:
#   - Leitura segura com while IFS= read -r
#   - Processamento de CSV
#   - Contadores por categoria
#   - Criação de arquivo de exemplo se não existir
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

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
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE)"

    ARQUIVO="${1:-/tmp/inventario.csv}"

    # Cria arquivo de exemplo se não existir
    if [[ ! -f "$ARQUIVO" ]]; then
        cat > "$ARQUIVO" << 'EOF'
HOST,IP,AMBIENTE,SO
web01,10.0.1.10,producao,ubuntu
web02,10.0.1.11,producao,ubuntu
db01,10.0.2.10,producao,rocky
cache01,10.0.3.10,homologacao,alpine
lb01,10.0.1.5,producao,debian
EOF
        echo "Arquivo de exemplo criado em $ARQUIVO"
    fi

    echo "=== Processamento de Inventário ==="
    echo "Arquivo: $ARQUIVO"
    echo

    # Pula cabeçalho (NR > 1) e processa linha a linha
    contador=0
    producao=0
    homologacao=0

    while IFS=',' read -r host ip ambiente so; do
        # Pula cabeçalho
        [[ "$host" == "HOST" ]] && continue

        # Remove espaços em branco extras
        host=$(echo "$host" | xargs)
        ip=$(echo "$ip" | xargs)
        ambiente=$(echo "$ambiente" | xargs)
        so=$(echo "$so" | xargs)

        echo "  Host: $host | IP: $ip | Ambiente: $ambiente | SO: $so"

        (( contador++ ))
        case "$ambiente" in
            producao)   (( producao++ )) ;;
            homologacao) (( homologacao++ )) ;;
        esac
    done < "$ARQUIVO"

    echo
    echo "Total processados: $contador"
    echo "Produção: $producao"
    echo "Homologação: $homologacao"

    log_info "fim"
}

main "$@"