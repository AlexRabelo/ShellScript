#!/usr/bin/env bash
#
# atualiza-config.sh - Atualiza arquivos de configuração com backup automático
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   atualiza-config.sh ARQUIVO VALOR_ANTIGO VALOR_NOVO
#
# Argumentos:
#   ARQUIVO          Arquivo de configuração a ser modificado (obrigatório)
#   VALOR_ANTIGO     Valor/substituir a ser buscado (obrigatório)
#   VALOR_NOVO       Novo valor para substituição (obrigatório)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico / arquivo não encontrado / sem permissão
#   2  Uso incorreto / argumentos inválidos
#
# Exemplos:
#   ./atualiza-config.sh /etc/nginx/nginx.conf "porta 8080;" "porta 80;"
#   ./atualiza-config.sh /etc/apache2/apache2.conf "Listen 8080" "Listen 80"
#
# Demonstra:
#   - Backup automático com timestamp antes da alteração
#   - Substituição segura com sed -i
#   - Verificação de sucesso da operação
#   - Limpeza de backups antigos (mantém 5 mais recentes)
#   - Modo dry-run para simulação
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

    [[ $# -eq 3 ]] || { usage >&2; die "forneça exatamente 3 argumentos (arquivo valor_antigo valor_novo)" 2; }

    local arquivo="$1"
    local valor_antigo="$2"
    local valor_novo="$3"

    [[ -f "$arquivo" ]] || die "arquivo de configuração não encontrado: $arquivo" 1
    [[ -r "$arquivo" ]] || die "sem permissão de leitura no arquivo: $arquivo" 1
    [[ -w "$arquivo" ]] || die "sem permissão de escrita no arquivo: $arquivo" 1

    echo "=== Atualização de Configuração ==="
    echo "Arquivo: $arquivo"
    echo "Substituindo: '$valor_antigo' → '$valor_novo'"
    echo

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] Backup que seria criado: ${arquivo}.bak.$(date +%F-%H%M%S)"
        log_info "[DRY-RUN] Alteração que seria feita: s/${valor_antigo}/${valor_novo}/g"
        log_info "[DRY-RUN] Diferença que seria mostrada:"
        grep "$valor_antigo" "$arquivo" || true
    else
        # Cria backup com timestamp
        local backup_file
        backup_file="${arquivo}.bak.$(date +%F-%H%M%S)"
        cp "$arquivo" "$backup_file"
        log_info "Backup criado: $backup_file"

        # Mostra o que será alterado
        echo "Linhas que serão alteradas:"
        grep "$valor_antigo" "$arquivo" || true
        echo

        # Executa a substituição
        sed -i "s/${valor_antigo}/${valor_novo}/g" "$arquivo"

        # Verifica se a substituição foi feita
        if grep "$valor_novo" "$arquivo" >/dev/null; then
            log_info "Substituição concluída com sucesso"
            echo "Linhas após a alteração:"
            grep "$valor_novo" "$arquivo" || true
        else
            log_erro "Substituição pode não ter sido concluída corretamente"
            # Restaura backup em caso de falha
            mv "$backup_file" "$arquivo"
            log_info "Arquivo restaurado a partir do backup"
            exit 1
        fi

        # Remove backups antigos (mantém apenas os 5 mais recentes)
        local backup_dir
        backup_dir="$(dirname "$arquivo")"
        local backup_pattern
        backup_pattern="$(basename "$arquivo").bak.*"
        ls -1t "$backup_dir"/$backup_pattern 2>/dev/null | tail -n +6 | xargs -r rm -f
    fi

    log_info "fim"
}

main "$@"