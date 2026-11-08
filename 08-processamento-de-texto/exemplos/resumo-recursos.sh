#!/usr/bin/env bash
#
# resumo-recursos.sh - Coleta resumo de utilização de recursos do sistema
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   resumo-recursos.sh
#
# Códigos de saída:
#   0  Sucesso
#
# Exemplos:
#   ./resumo-recursos.sh
#
# Demonstra:
#   - Coleta de métricas de CPU, memória, disco, carga e processos
#   - Formatação de unidades legíveis (KB, MB, GB)
#   - Uso de comandos do sistema: lscpu, vmstat, df, free, ps
#   - Saída estruturada para health checks rápidos
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
    local msg
    msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

die() {
    local msg="$1"
    local codigo
    codigo="${2:-1}"
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

    echo "=== RESUMO DE RECURSOS DO SISTEMA ==="
    echo "Timestamp: $(date '+%F %T %Z')"
    echo "Hostname:  $(hostname)"
    echo

    # CPU
    echo "--- CPU ---"
    if command -v lscpu >/dev/null; then
        lscpu | grep "Model name:" | cut -d: -f2 | xargs echo "Modelo:"
        lscpu | grep "^CPU(s):" | awk '{print "Núcleos: " $2}'
    else
        echo "Modelo: $(uname -m)"
        echo "Núcleos: $(nproc)"
    fi

    # Carga média
    echo "Carga média: $(cat /proc/loadavg | awk '{print $1" (1min), "$2" (5min), "$3" (15min)"}')"

    # Uso de CPU (aproximado)
    cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    cpu_uso=$((100 - cpu_idle))
    echo "Uso aproximado de CPU: ${cpu_uso}%"
    echo

    # Memória
    echo "--- MEMÓRIA ---"
    if [[ -f /proc/meminfo ]]; then
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_livre=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        mem_usada=$((mem_total - mem_livre))
        mem_percent=$((mem_usada * 100 / mem_total))

        echo "Total:     $(numfmt --to=iec $((mem_total * 1024)))"
        echo "Livre:     $(numfmt --to=iec $((mem_livre * 1024)))"
        echo "Usada:     $(numfmt --to=iec $((mem_usada * 1024))) ($mem_percent%)"
    else
        echo "Informações de memória não disponíveis"
    fi
    echo

    # Disco
    echo "--- DISCO (/) ---"
    df -h / | awk 'NR==1 {print}'  # Cabeçalho
    df -h / | awk 'NR==2 {print "Total: " $2 ", Usado: " $3 ", Livre: " $4 ", Uso: " $5}'
    echo

    # Processos
    echo "--- PROCESSOS ---"
    total_procs=$(ps aux --no-headers | wc -l)
    procs_rodando=$(ps aux --no-headers | awk '$8 ~ /^R/ {count++} END {print count+0}')
    procs_dormindo=$(ps aux --no-headers | awk '$8 ~ /^S/ {count++} END {print count+0}')
    procs_zumbi=$(ps aux --no-headers | awk '$8 ~ /^Z/ {count++} END {print count+0}')

    echo "Total:     $total_procs"
    echo "Rodando:   $procs_rodando"
    echo "Dormindo:  $procs_dormindo"
    echo "Zumbis:    $procs_zumbi"
    echo

    # Top 5 processos por CPU
    echo "--- TOP 5 POR CPU ---"
    ps aux --sort=-%cpu | head -6
    echo

    # Top 5 processos por memória
    echo "--- TOP 5 POR MEMÓRIA ---"
    ps aux --sort=-%mem | head -6
    echo

    log_info "fim"
}

main "$@"