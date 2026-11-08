#!/usr/bin/env bash
#
# modo-estrito.sh - Demonstra o efeito do modo estrito (set -euo pipefail)
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   modo-estrito.sh [--com-estrito|--sem-estrito|--armadilha]
#
# Argumentos:
#   --com-estrito   Executa demonstração com modo estrito ativado
#   --sem-estrito   Executa demonstração com modo estrito desativado (perigoso!)
#   --armadilha     Mostra armadilha comum do set -e em contextos condicionais
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto
#
# Exemplos:
#   ./modo-estrito.sh              # Executa ambas as versões para comparação
#   ./modo-estrito.sh --com-estrito
#   ./modo-estrito.sh --sem-estrito
#   ./modo-estrito.sh --armadilha
#
# Demonstra:
#   - Diferença entre scripts com e sem modo estrito
#   - Armadilhas comuns do set -e
#   - Importância de usar set -Eeuo pipefail em scripts de produção
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

# --- Versão SEM modo estrito (perigosa) ---
versao_sem_estrito() {
    log_info "=== VERSÃO SEM MODO ESTRITO ==="

    # Variável não definida - não falha, vira string vazia
    log_info "Diretório alvo: ${DIRETORIO_ALVO}/arquivo.txt"
    rm -rf "${DIRETORIO_ALVO}/arquivo.txt" 2>/dev/null || true
    log_info "rm executou (mesmo com variável vazia, apaga o diretório atual!)"

    # Comando que falha - script continua
    log_info "Tentando acessar arquivo inexistente..."
    cat /arquivo/que/nao/existe 2>/dev/null || true
    log_info "cat falhou mas script continuou"

    # Pipe mascara erro - só o último código conta
    log_info "Pipeline com falha no meio:"
    echo "dados" | grep -c "padrão_inexistente" || true
    log_info "Código de saída do pipeline: $? (deveria ser 1, mas é 0)"

    # Função com erro não propaga
    funcao_perigosa() {
        log_info "Dentro da função, erro não tratado:"
        false
        log_info "Após false - função continua"
    }
    funcao_perigosa
    log_info "Após chamada da função - script continua"
}

# --- Versão COM modo estrito (segura) ---
versao_com_estrito() {
    log_info "=== VERSÃO COM MODO ESTRITO (set -euo pipefail) ==="

    # Subshell isolado para não matar o script principal
    (
        set -Eeuo pipefail

        log_info "Variável não definida:"
        # shellcheck disable=SC2154
        echo "Diretório: ${DIRETORIO_ALVO}/arquivo.txt"
        log_info "NÃO EXECUTA ESTA LINHA - script aborta acima"

    ) || log_erro "Subshell abortou como esperado (variável não definida)"

    # Comando que falha
    (
        set -Eeuo pipefail
        log_info "Comando que falha:"
        cat /arquivo/que/nao/existe
        log_info "NÃO EXECUTA ESTA LINHA"
    ) || log_erro "Subshell abortou como esperado (comando falhou)"

    # Pipe com pipefail
    (
        set -Eeuo pipefail
        log_info "Pipeline com falha no meio (pipefail ativo):"
        echo "dados" | grep -c "padrão_inexistente" || true
        log_info "NÃO EXECUTA ESTA LINHA"
    ) || log_erro "Subshell abortou como esperado (pipe falhou)"

    # Erro em função propaga
    (
        set -Eeuo pipefail
        funcao_segura() {
            log_info "Dentro da função:"
            false
            log_info "NÃO EXECUTA ESTA LINHA"
        }
        funcao_segura
        log_info "NÃO EXECUTA ESTA LINHA"
    ) || log_erro "Subshell abortou como esperado (erro na função)"
}

# --- Demonstração de armadilha do set -e ---
armadilha_set_e() {
    log_info "=== ARMADILHA: set -e NÃO dispara em contextos condicionais ==="

    (
        set -e
        log_info "Teste 1: if com comando que falha"
        if false; then
            log_info "no if"
        fi
        log_info "Continua após if false (comportamento esperado)"

        log_info "Teste 2: && com comando que falha"
        false && log_info "não executa"
        log_info "Continua após false && (comportamento esperado)"

        log_info "Teste 3: Função chamada em if"
        funcao_que_falha() { false; }
        if funcao_que_falha; then
            log_info "no if"
        fi
        log_info "Continua - erro dentro da função NÃO propaga no if"
    )

    log_info "Solução: usar 'set -E' (herança de trap ERR) + trap ERR"
    (
        set -Eeuo pipefail
        trap 'log_erro "ERRO capturado pelo trap ERR na linha $LINENO"' ERR

        funcao_com_trap() {
            false
        }

        if funcao_com_trap; then
            log_info "no if"
        fi
        log_info "NÃO EXECUTA - trap ERR disparou mesmo no if"
    ) || true
}

# --- Lógica Principal --------------------------------------------------------
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

    local modo="${1:-ambos}"

    case "$modo" in
        --sem-estrito)
            versao_sem_estrito
            ;;
        --com-estrito)
            versao_com_estrito
            ;;
        --armadilha)
            armadilha_set_e
            ;;
        *)
            versao_sem_estrito
            echo
            versao_com_estrito
            echo
            armadilha_set_e
            ;;
    esac

    log_info "fim"
}

main "$@"