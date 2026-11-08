#!/usr/bin/env bash
#
# analisa-erros-hora.sh - Conta erros por hora em arquivos de log
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   analisa-erros-hora.sh ARQUIVO_LOG
#
# Argumentos:
#   ARQUIVO_LOG   Arquivo de log a ser analisado (obrigatório)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico / arquivo não encontrado
#   2  Uso incorreto
#
# Exemplos:
#   ./analisa-erros-hora.sh /var/log/app.log
#   ./analisa-erros-hora.sh /var/log/nginx/error.log
#
# Demonstra:
#   - Contagem de ocorrências por hora em logs
#   - Filtro case-insensitive para "ERROR"/"ERRO"
#   - Processamento com awk para extrair horários
#   - Formatação de saída em tabela
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

    [[ $# -eq 1 ]] || { usage >&2; die "forneça exatamente 1 argumento (arquivo de log)" 2; }

    local log_file="$1"
    [[ -f "$log_file" ]] || die "arquivo de log não encontrado: $log_file" 1
    [[ -r "$log_file" ]] || die "sem permissão de leitura no arquivo de log: $log_file" 1

    echo "=== Análise de Erros por Hora ==="
    echo "Arquivo: $log_file"
    echo

    # Processa o log contando erros por hora
    # Formato assumido: [12/Oct/2026:14:35:10 +0000] ou similar
    awk '
    {
        # Extrai a hora do timestamp (formato [dd/mmm/yyyy:HH:MM:SS
        if (match($0, /\[[0-9]{2}\/[a-zA-Z]{3}\/[0-9]{4}:([0-9]{2})/, arr)) {
            hora = arr[1]
            # Converte para minúscula para case-insensitive
            linha_lower = tolower($0)
            if (linha_lower ~ /error|erro/) {
                contagem[hora]++
            }
            total_linhas++
        }
    }
    END {
        printf "%-8s %-12s %s\n", "HORA", "ERROS", "PERCENTUAL"
        printf "%-8s %-12s %s\n", "--------", "----------", "----------"
        # Recalcula total de erros para percentual correto
        total_erros = 0
        for (h in contagem) {
            total_erros += contagem[h]
        }
        for (h in contagem) {
            percentual = (contagem[h] / total_erros) * 100
            printf "%-8s %-12d %-6.2f%%\n", h ":00", contagem[h], percentual
        }
    }
    ' "$log_file" | sort -n

    # Também mostra total de erros encontrados
    total_erros=$(awk 'tolower($0) ~ /error|erro/ {count++} END {print count+0}' "$log_file")
    echo
    echo "Total de erros encontrados: $total_erros"

    log_info "fim"
}

main "$@"