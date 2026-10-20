#!/usr/bin/env bash
#
# trap-limpeza.sh - Demonstra limpeza garantida com trap EXIT/INT/TERM
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   trap-limpeza.sh [--simula-falha|--simula-interrupcao|--simula-termino]
#
# Argumentos:
#   --simula-falha          Simula erro durante processamento (trap ERR)
#   --simula-interrupcao    Simula trabalho longo (teste Ctrl+C / SIGINT)
#   --simula-termino        Simula trabalho longo (teste SIGTERM / kill)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico / lock já em uso
#   130  Interrompido pelo usuário (SIGINT)
#   143  Recebeu sinal de término (SIGTERM)
#
# Exemplos:
#   ./trap-limpeza.sh                       # Execução normal
#   ./trap-limpeza.sh --simula-falha        # Testa trap ERR
#   ./trap-limpeza.sh --simula-interrupcao  # Teste Ctrl+C em outro terminal
#   ./trap-limpeza.sh --simula-termino      # Teste kill -TERM em outro terminal
#
# Demonstra:
#   - Trap EXIT para limpeza garantida (sempre executa)
#   - Trap INT/TERM para sinais de interrupção
#   - Trap ERR para erros não tratados
#   - Lock exclusivo com flock
#   - Criação e limpeza de recursos temporários
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"
readonly TMP_BASE="/tmp/${SCRIPT_NAME%.sh}"

_DRY_RUN=0
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
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO  "$@"; }
log_debug() { log DEBUG "$@"; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

# --- Variáveis de estado para limpeza ---
TMP_DIR=""
ARQUIVO_TEMP=""
LOCK_FD=9
LOCK_FILE="${TMP_BASE}.lock"

# --- Função de limpeza centralizada ---
cleanup() {
    local codigo_saida=$?
    log_info "=== LIMPEZA INICIADA (código de saída: $codigo_saida) ==="

    # 1. Remove diretório temporário
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        log_info "Removendo diretório temporário: $TMP_DIR"
        rm -rf -- "$TMP_DIR"
        TMP_DIR=""
    fi

    # 2. Remove arquivo temporário específico
    if [[ -n "$ARQUIVO_TEMP" && -f "$ARQUIVO_TEMP" ]]; then
        log_info "Removendo arquivo temporário: $ARQUIVO_TEMP"
        rm -f -- "$ARQUIVO_TEMP"
        ARQUIVO_TEMP=""
    fi

    # 3. Libera lock (fecha FD)
    if [[ -n "${LOCK_FD:-}" ]]; then
        eval "exec ${LOCK_FD}>&-"
        log_info "Lock liberado (FD $LOCK_FD fechado)"
    fi

    # 4. Remove arquivo de lock se fomos nós que criamos
    if [[ -f "$LOCK_FILE" ]]; then
        # Só remove se o PID no lock for nosso
        if [[ -r "$LOCK_FILE" ]] && grep -q "^$$\$" "$LOCK_FILE" 2>/dev/null; then
            rm -f -- "$LOCK_FILE"
            log_info "Arquivo de lock removido"
        fi
    fi

    if [[ $codigo_saida -eq 0 ]]; then
        log_info "=== SCRIPT TERMINOU COM SUCESSO ==="
    else
        log_erro "=== SCRIPT TERMINOU COM FALHA (código: $codigo_saida) ==="
    fi
}

# --- Traps ---
trap cleanup EXIT
trap 'log_aviso "Interrompido pelo usuário (SIGINT)"; exit 130' INT
trap 'log_aviso "Recebido SIGTERM"; exit 143' TERM
trap 'log_erro "Erro na linha $LINENO: $BASH_COMMAND"' ERR

# --- Adquire lock exclusivo ---
adquirir_lock() {
    log_info "Tentando adquirir lock: $LOCK_FILE"
    exec {LOCK_FD}> "$LOCK_FILE"
    if ! flock -n "$LOCK_FD"; then
        log_erro "Outra instância já está rodando (PID: $(cat "$LOCK_FILE" 2>/dev/null || echo 'desconhecido'))"
        exit 1
    fi
    echo "$$" >&"$LOCK_FD"
    log_info "Lock adquirido com sucesso (FD: $LOCK_FD)"
}

# --- Cria recursos temporários ---
criar_recursos() {
    log_info "Criando recursos temporários..."

    TMP_DIR="$(mktemp -d -t "${SCRIPT_NAME%.sh}.XXXXXX")"
    log_info "Diretório temporário: $TMP_DIR"

    ARQUIVO_TEMP="${TMP_DIR}/dados_processamento.txt"
    echo "inicio,$(date +%s)" > "$ARQUIVO_TEMP"
    log_info "Arquivo temporário criado: $ARQUIVO_TEMP"

    # Simula arquivos de trabalho
    for i in {1..3}; do
        echo "processo-$i,$(date +%s),dados" >> "${TMP_DIR}/work-$i.tmp"
    done
    log_info "Arquivos de trabalho criados em $TMP_DIR"
}

# --- Simula processamento ---
processar() {
    local cenario="${1:-normal}"

    log_info "Iniciando processamento (cenário: $cenario)..."

    case "$cenario" in
        --simula-falha)
            log_info "Simulando falha no meio do processamento..."
            sleep 1
            echo "dados processados" >> "$ARQUIVO_TEMP"
            # Erro intencional
            false
            ;;
        --simula-interrupcao)
            log_info "Simulando trabalho longo (pressione Ctrl+C para testar)..."
            for i in {1..10}; do
                echo "etapa-$i,$(date +%s)" >> "$ARQUIVO_TEMP"
                log_info "Etapa $i/10 concluída"
                sleep 1
            done
            ;;
        --simula-termino)
            log_info "Simulando trabalho longo (envie SIGTERM: kill -TERM $$)..."
            for i in {1..10}; do
                echo "etapa-$i,$(date +%s)" >> "$ARQUIVO_TEMP"
                log_info "Etapa $i/10 concluída"
                sleep 1
            done
            ;;
        *)
            log_info "Processamento normal..."
            for i in {1..3}; do
                echo "etapa-$i,$(date +%s)" >> "$ARQUIVO_TEMP"
                log_info "Etapa $i/3 concluída"
                sleep 0.5
            done
            ;;
    esac

    echo "fim,$(date +%s)" >> "$ARQUIVO_TEMP"
    log_info "Processamento concluído com sucesso"
}

# --- Mostra estado dos recursos (para verificação) ---
mostrar_estado() {
    log_info "=== ESTADO DOS RECURSOS ==="
    log_info "TMP_DIR: ${TMP_DIR:-'(não criado)'}"
    log_info "ARQUIVO_TEMP: ${ARQUIVO_TEMP:-'(não criado)'}"
    log_info "LOCK_FILE: $LOCK_FILE (existe: $([[ -f "$LOCK_FILE" ]] && echo 'sim' || echo 'não'))"
    if [[ -d "${TMP_DIR:-}" ]]; then
        log_info "Conteúdo de $TMP_DIR:"
        find "$TMP_DIR" -maxdepth 1 -ls | sed 's/^/  /' >&2
    fi
    if [[ -f "${ARQUIVO_TEMP:-}" ]]; then
        log_info "Conteúdo de $ARQUIVO_TEMP:"
        cat "$ARQUIVO_TEMP" | sed 's/^/  /' >&2
    fi
}

# --- Lógica Principal --------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    log_info "=== INÍCIO: $SCRIPT_NAME (PID: $$) ==="
    log_info "Cenário: ${1:-normal}"

    adquirir_lock
    criar_recursos
    mostrar_estado

    echo
    processar "${1:-normal}"

    echo
    mostrar_estado

    log_info "Finalizando normalmente (cleanup será executado via trap EXIT)"
}

usage() {
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

main "$@"