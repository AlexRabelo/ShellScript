#!/usr/bin/env bash
#
# limpa-logs.sh - Remove arquivos de log antigos com segurança (dry-run por padrão)
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   limpa-logs.sh [DIRETORIO] [DIAS] [--exec]
#
# Argumentos:
#   DIRETORIO    Diretório a ser limpo (padrão: /var/log)
#   DIAS         Arquivos com mais de N dias (padrão: 7)
#   --exec       Executa a limpeza (padrão: dry-run apenas lista)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico / diretório não existe
#   2  Uso incorreto / argumentos inválidos
#
# Exemplos:
#   ./limpa-logs.sh
#   ./limpa-logs.sh /var/log 30
#   ./limpa-logs.sh /var/log 7 --exec
#
# Demonstra:
#   - Loop for sobre glob
#   - find com -mtime
#   - Confirmação antes de excluir
#   - Dry-run por padrão
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

    diretorio="${1:-/var/log}"
    dias="${2:-7}"
    modo="${3:-dry-run}"

    [[ -d "$diretorio" ]] || { die "Diretório '$diretorio' não existe" 1; }
    [[ "$dias" =~ ^[0-9]+$ ]] || { die "Dias deve ser número inteiro" 2; }

    echo "=== Limpeza de Logs ==="
    echo "Diretório: $diretorio"
    echo "Critério: arquivos .log e .log.* mais velhos que $dias dia(s)"
    echo "Modo: $modo"
    echo

    encontrados=()
    tamanho_total=0

    # Busca arquivos .log e .log.* com mais de $dias dias
    while IFS= read -r -d '' arquivo; do
        [[ -f "$arquivo" ]] || continue
        tamanho=$(stat -c%s "$arquivo" 2>/dev/null || stat -f%z "$arquivo" 2>/dev/null)
        encontrados+=("$arquivo")
        tamanho_total=$(( tamanho_total + tamanho ))
    done < <(find "$diretorio" -type f \( -name "*.log" -o -name "*.log.*" \) -mtime "+$dias" -print0 2>/dev/null)

    if (( ${#encontrados[@]} == 0 )); then
        echo "Nenhum arquivo encontrado para limpeza."
        exit 0
    fi

    echo "Arquivos que seriam removidos (${#encontrados[@]}):"
    for arq in "${encontrados[@]}"; do
        tam_human=$(numfmt --to=iec-i --suffix=B "$(stat -c%s "$arq" 2>/dev/null || stat -f%z "$arq" 2>/dev/null)")
        echo "  $arq ($tam_human)"
    done

    total_human=$(numfmt --to=iec-i --suffix=B "$tamanho_total")
    echo "Espaço total a liberar: $total_human"

    if [[ "$modo" == "--exec" ]]; then
        echo
        read -rp "Confirmar exclusão? [s/N] " conf
        [[ "${conf,,}" == "s" ]] || { echo "Cancelado."; exit 0; }

        for arq in "${encontrados[@]}"; do
            run rm -f "$arq" && echo "Removido: $arq" || echo "Falha ao remover: $arq" >&2
        done
        echo "Limpeza concluída."
    else
        echo
        echo "Modo DRY-RUN: nenhum arquivo foi removido."
        echo "Para executar: $0 $diretorio $dias --exec"
    fi

    log_info "fim"
}

main "$@"