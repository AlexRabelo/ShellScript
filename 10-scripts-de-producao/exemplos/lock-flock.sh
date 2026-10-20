#!/usr/bin/env bash
#
# lock-flock.sh - Demonstra prevenção de execução concorrente com flock
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   lock-flock.sh [--tenta-segunda|--com-timeout|--lock-compartilhado|--segura-lock|--funcao|--armadilhas|--concorrencia]
#
# Opções:
#   --tenta-segunda          Lock exclusivo básico (não bloqueante)
#   --com-timeout            Lock com timeout de espera
#   --lock-compartilhado     Lock compartilhado (leitura) vs exclusivo (escrita)
#   --segura-lock            Segura lock por 30s (para teste de concorrência)
#   --funcao                 Lock dentro de função (FD herdado)
#   --armadilhas             Mostra armadilhas comuns do flock
#   --concorrencia           Instruções para teste de concorrência real
#
# Códigos de saída:
#   0  Sucesso / lock adquirido
#   1  Falha ao adquirir lock / timeout
#   2  Uso incorreto
#
# Exemplos:
#   ./lock-flock.sh                       # Demonstra todos os modos
#   ./lock-flock.sh --tenta-segunda       # Testa lock exclusivo não bloqueante
#   ./lock-flock.sh --com-timeout         # Testa lock com timeout
#   ./lock-flock.sh --lock-compartilhado  # Testa lock compartilhado
#   ./lock-flock.sh --segura-lock         # Segura lock por 30s (terminal 1)
#   ./lock-flock.sh --tenta-segunda       # Tenta adquirir (terminal 2 - falha)
#
# Demonstra:
#   - Lock exclusivo não bloqueante (flock -n)
#   - Lock com timeout (flock -w)
#   - Lock compartilhado vs exclusivo (flock -s)
#   - Lock dentro de funções com FD herdado
#   - Armadilhas comuns e como evitá-las
#   - Teste de concorrência real entre terminais
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.sh}.lock"

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

# --- Lock exclusivo básico (não bloqueante) ---
lock_exclusivo_basico() {
    log_info "=== LOCK EXCLUSIVO BÁSICO (flock -n) ==="

    local fd=9
    eval "exec ${fd}> \"$LOCK_FILE\""

    log_info "Tentando adquirir lock exclusivo (não bloqueante)..."
    if flock -n "$fd"; then
        log_info "Lock adquirido com sucesso"
        echo "$$" >&"$fd"

        log_info "Simulando trabalho crítico (3s)..."
        sleep 3

        log_info "Trabalho concluído, liberando lock"
    else
        log_erro "Falha ao adquirir lock - outra instância rodando (PID: $(cat "$LOCK_FILE" 2>/dev/null || echo '?'))"
        eval "exec ${fd}>&-"
        return 1
    fi

    eval "exec ${fd}>&-"
}

# --- Lock com timeout ---
lock_com_timeout() {
    log_info "=== LOCK COM TIMEOUT (flock -w) ==="

    local fd=9
    local timeout=5
    eval "exec ${fd}> \"$LOCK_FILE\""

    log_info "Tentando adquirir lock com timeout de ${timeout}s..."
    if flock -w "$timeout" "$fd"; then
        log_info "Lock adquirido com sucesso"
        echo "$$" >&"$fd"

        log_info "Simulando trabalho crítico (2s)..."
        sleep 2

        log_info "Trabalho concluído"
    else
        log_erro "Timeout: não conseguiu lock em ${timeout}s (PID atual no lock: $(cat "$LOCK_FILE" 2>/dev/null || echo '?'))"
        eval "exec ${fd}>&-"
        return 1
    fi

    eval "exec ${fd}>&-"
}

# --- Lock compartilhado (leitura) vs exclusivo (escrita) ---
lock_compartilhado_vs_exclusivo() {
    log_info "=== LOCK COMPARTILHADO (SHARED) VS EXCLUSIVO ==="

    local fd=9
    eval "exec ${fd}> \"$LOCK_FILE\""

    log_info "Adquirindo lock COMPARTILHADO (leitura)..."
    if flock -s -n "$fd"; then
        log_info "Lock compartilhado adquirido - múltiplos leitores permitidos"
        echo "READER-$$" >&"$fd"
        log_info "Simulando leitura (2s)..."
        sleep 2
        log_info "Leitura concluída"
    else
        log_erro "Não conseguiu lock compartilhado (escritor ativo?)"
        eval "exec ${fd}>&-"
        return 1
    fi

    eval "exec ${fd}>&-"
}

# --- Demonstração de concorrência real ---
demo_concorrencia() {
    log_info "=== DEMO: CONCORRÊNCIA REAL (rode em terminais separados) ==="
    log_info ""
    log_info "Terminal 1: ./lock-flock.sh --segura-lock"
    log_info "Terminal 2: ./lock-flock.sh --tenta-segunda"
    log_info ""
    log_info "Ou teste com timeout:"
    log_info "Terminal 1: ./lock-flock.sh --segura-lock"
    log_info "Terminal 2: ./lock-flock.sh --com-timeout"
    log_info ""
    log_info "Para lock compartilhado:"
    log_info "Terminal 1: ./lock-flock.sh --lock-compartilhado"
    log_info "Terminal 2: ./lock-flock.sh --lock-compartilhado (funciona - ambos leitores)"
    log_info "Terminal 3: ./lock-flock.sh --tenta-segunda (falha - escritor bloqueia)"
}

# --- Segura lock por tempo prolongado (para testar concorrência) ---
segura_lock() {
    log_info "=== SEGURA LOCK POR 30s (PARA TESTE DE CONCORRÊNCIA) ==="

    local fd=9
    eval "exec ${fd}> \"$LOCK_FILE\""

    log_info "Tentando adquirir lock exclusivo..."
    if flock -n "$fd"; then
        log_info "Lock adquirido - segurando por 30 segundos"
        echo "$$" >&"$fd"

        for i in {30..1}; do
            printf '\rLock ativo - liberando em %2ds ' "$i"
            sleep 1
        done
        echo
        log_info "Lock liberado após 30s"
    else
        log_erro "Não conseguiu lock (outro PID: $(cat "$LOCK_FILE" 2>/dev/null || echo '?'))"
        eval "exec ${fd}>&-"
        return 1
    fi

    eval "exec ${fd}>&-"
}

# --- Lock em função (herança de FD) ---
lock_em_funcao() {
    log_info "=== LOCK DENTRO DE FUNÇÃO (FD HERDADO) ==="

    adquirir_lock_interno() {
        local fd=9
        eval "exec ${fd}> \"$LOCK_FILE\""
        if flock -n "$fd"; then
            echo "$$" >&"$fd"
            return 0
        else
            eval "exec ${fd}>&-"
            return 1
        fi
    }

    liberar_lock_interno() {
        local fd=9
        eval "exec ${fd}>&-"
    }

    log_info "Chamando função para adquirir lock..."
    if adquirir_lock_interno; then
        log_info "Lock adquirido dentro da função"
        sleep 1
        log_info "Trabalho na função concluído"
        liberar_lock_interno
        log_info "Lock liberado"
    else
        log_erro "Falha ao adquirir lock na função"
        return 1
    fi
}

# --- Armadilhas comuns ---
armadilhas() {
    log_info "=== ARMADILHAS COMUNS DO FLOCK ==="
    log_info ""
    log_info "1. Esquecer de fechar FD: o lock só libera no fim do script"
    log_info "   Solução: sempre fechar FD ou usar subshell"
    log_info ""
    log_info "2. Usar arquivo de lock em /tmp (limpo no reboot)"
    log_info "   Solução: usar /var/lock/ ou diretório persistente"
    log_info ""
    log_info "3. flock -n falha silenciosamente se arquivo não existe"
    log_info "   Solução: arquivo é criado automaticamente pelo redirecionamento"
    log_info ""
    log_info "4. Lock em script sourced (source script.sh) - FD vaza"
    log_info "   Solução: usar subshell (script.sh) ou fechar FD explicitamente"
    log_info ""
    log_info "5. Múltiplos FDs no mesmo arquivo - flock conta por FD, não por arquivo"
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

    local modo="${1:-basico}"

    case "$modo" in
        --tenta-segunda)
            lock_exclusivo_basico
            ;;
        --com-timeout)
            lock_com_timeout
            ;;
        --lock-compartilhado)
            lock_compartilhado_vs_exclusivo
            ;;
        --segura-lock)
            segura_lock
            ;;
        --funcao)
            lock_em_funcao
            ;;
        --armadilhas)
            armadilhas
            ;;
        --concorrencia)
            demo_concorrencia
            ;;
        *)
            lock_exclusivo_basico
            echo
            lock_com_timeout
            echo
            lock_compartilhado_vs_exclusivo
            echo
            armadilhas
            echo
            demo_concorrencia
            ;;
    esac

    log_info "fim"
}

main "$@"