#!/usr/bin/env bash
#
# NOME_DO_SCRIPT.sh - Descrição curta em uma linha do que o script faz
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   NOME_DO_SCRIPT.sh [-h|--help] [-v|--verbose] [-n|--dry-run] ARGUMENTOS
#
# Opções:
#   -h, --help     Exibe esta ajuda e sai
#   -v, --verbose  Habilita log nível DEBUG
#   -n, --dry-run  Simula execução sem alterar estado (quando aplicável)
#
# Argumentos:
#   ARG1    Descrição do primeiro argumento (obrigatório)
#   ARG2    Descrição do segundo argumento (opcional)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto / argumentos inválidos
#   3  Pré-requisito ausente (comando, arquivo, permissão)
#   4  Erro de permissão / execução
#
# Exemplos:
#   NOME_DO_SCRIPT.sh /caminho/origem /caminho/destino
#   NOME_DO_SCRIPT.sh -v -n "servidor-producao"
#   NOME_DO_SCRIPT.sh --dry-run --verbose /etc /backup
#
# Dependências:
#   - bash 4.0+
#   - comando1 (pacote: pacote1)
#   - comando2 (pacote: pacote2)
#
# Notas:
#   - Requer execução como root para operações de sistema
#   - Em modo dry-run, apenas exibe o que seria feito
#   - Logs salvos em /tmp/NOME_DO_SCRIPT.log
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
# -E: herda trap ERR em funções/subshells
# -e: aborta em erro (comando retorna non-zero)
# -u: erro ao usar variável não definida
# -o pipefail: pipeline falha se qualquer comando falhar
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
# SCRIPT_DIR disponível para scripts que precisam do diretório do script
# readonly SCRIPT_DIR
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

# Variáveis de controle
DRY_RUN=0
VERBOSE=0

# --- Funções de Log ----------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$msg" ;;
        *)          printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO  "$@"; }
log_sucesso() { log OK    "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO  "$@"; }
log_debug() { log DEBUG "$@"; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

# --- Limpeza e Tratamento de Sinais ------------------------------------------
cleanup() {
    local codigo=$?
    # Limpeza de recursos temporários aqui
    if [[ $codigo -eq 0 ]]; then
        log_info "terminou com sucesso"
    else
        log_erro "terminou com falha (código ${codigo})"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário (SIGINT)" 130' INT
trap 'die "recebeu sinal de término (SIGTERM)" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades --------------------------------------------------------------
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

# --- Ajuda -------------------------------------------------------------------
usage() {
    # Extrai o cabeçalho de comentários (linhas 3 até a linha antes de =====)
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

# --- Lógica Principal --------------------------------------------------------
main() {
    local args=()

    # Parse de opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    # Validação de argumentos posicionais
    # [[ ${#args[@]} -eq 1 ]] || { usage >&2; die "informe exatamente 1 argumento" 2; }

    # Pré-requisitos
    # requer_comando date
    # requer_comando mktemp

    log_info "início (args=${args[*]}, dry-run=${DRY_RUN}, verbose=${VERBOSE})"

    # ----- Sua lógica começa aqui -----
    # Exemplo:
    # for arg in "${args[@]}"; do
    #     log_info "Processando: $arg"
    # done
    # ----- Sua lógica termina aqui -----

    log_info "fim"
}

# --- Invocação ---
main "$@"