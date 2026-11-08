#!/usr/bin/env bash
#
# testa-arquivo.sh - demonstra todos os testes de arquivo.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   testa-arquivo.sh CAMINHO
#
# Exemplo:
#   testa-arquivo.sh /etc/passwd
#
# =============================================================================

set -Eeuo pipefail

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
    sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
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

    # Validação de argumentos vai aqui
    # Exemplo: [[ $# -eq 2 ]] || { usage >&2; die "forneça exatamente 2 argumentos" 2; }

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE)"

    # Lógica principal do script vai aqui
    # Exemplo:
    # for arg in "$@"; do
    #     log_info "Processando: $arg"
    # done

    [[ $# -eq 1 ]] || { usage >&2; die "Uso: $0 CAMINHO" 2; }

    caminho="$1"

    echo "Testando: $caminho"
    echo

    # Teste de existência
    if [[ -e "$caminho" ]]; then
        echo "✓ -e  Existe"
    else
        echo "✗ -e  Não existe"
    fi

    # Tipo
    if [[ -f "$caminho" ]]; then echo "✓ -f  Arquivo regular"; else echo "✗ -f  Não é arquivo regular"; fi
    if [[ -d "$caminho" ]]; then echo "✓ -d  Diretório"; else echo "✗ -d  Não é diretório"; fi
    if [[ -L "$caminho" ]]; then echo "✓ -L  Link simbólico"; else echo "✗ -L  Não é link"; fi

    # Permissões
    if [[ -r "$caminho" ]]; then echo "✓ -r  Legível"; else echo "✗ -r  Não legível"; fi
    if [[ -w "$caminho" ]]; then echo "✓ -w  Gravável"; else echo "✗ -w  Não gravável"; fi
    if [[ -x "$caminho" ]]; then echo "✓ -x  Executável"; else echo "✗ -x  Não executável"; fi

    # Tamanho
    if [[ -s "$caminho" ]]; then echo "✓ -s  Não vazio"; else echo "✗ -s  Vazio (ou não existe)"; fi

    echo
    echo "Resumo dos operadores de arquivo:"
    echo "  -e  existe          -f  arquivo regular    -d  diretório"
    echo "  -L  link simbólico  -r  legível            -w  gravável"
    echo "  -x  executável      -s  não vazio (tamanho > 0)"

    log_info "fim"
}

main "$@"