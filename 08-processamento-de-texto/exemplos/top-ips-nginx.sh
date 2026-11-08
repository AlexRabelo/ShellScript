#!/usr/bin/env bash
#
# top-ips-nginx.sh - analisa access.log do Nginx e mostra top IPs.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   top-ips-nginx.sh [ARQUIVO_LOG] [TOP_N]
#
# Analisa o access.log do Nginx (ou qualquer log no formato comum) e mostra
# os IPs com mais requisições, usando o pipeline clássico: awk -> sort -> uniq -c -> sort -rn -> head
#
# Exemplos:
#   top-ips-nginx.sh                    # usa /var/log/nginx/access.log, top 10
#   top-ips-nginx.sh access.log 5       # arquivo específico, top 5
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME
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

    local arquivo
    arquivo="${1:-/var/log/nginx/access.log}"
    local top_n
    top_n="${2:-10}"

    # Valida se TOP_N é um número positivo
    [[ "$top_n" =~ ^[0-9]+$ ]] || die "TOP_N deve ser um número inteiro positivo" 2
    [[ "$top_n" -gt 0 ]] || die "TOP_N deve ser maior que zero" 2

    # Se o arquivo de log não existir, cria um de exemplo para demonstração
    if [[ ! -f "$arquivo" ]]; then
        log_info "Arquivo de log não encontrado. Criando exemplo em $arquivo"
        mkdir -p "$(dirname "$arquivo")"
        cat > "$arquivo" << 'EOF'
192.168.1.10 - - [12/Oct/2026:10:00:01 +0000] "GET / HTTP/1.1" 200 612
192.168.1.11 - - [12/Oct/2026:10:00:02 +0000] "POST /api/login HTTP/1.1" 200 345
192.168.1.10 - - [12/Oct/2026:10:00:03 +0000] "GET /dashboard HTTP/1.1" 200 1234
192.168.1.12 - - [12/Oct/2026:10:00:04 +0000] "GET / HTTP/1.1" 404 153
192.168.1.10 - - [12/Oct/2026:10:00:05 +0000] "GET /api/data HTTP/1.1" 200 890
203.0.113.5 - - [12/Oct/2026:10:00:06 +0000] "GET /admin HTTP/1.1" 403 234
203.0.113.5 - - [12/Oct/2026:10:00:07 +0000] "GET /admin/login HTTP/1.1" 403 234
203.0.113.5 - - [12/Oct/2026:10:00:08 +0000] "POST /admin/login HTTP/1.1" 200 567
192.168.1.13 - - [12/Oct/2026:10:00:09 +0000] "GET / HTTP/1.1" 200 612
198.51.100.2 - - [12/Oct/2026:10:00:10 +0000] "GET /wp-login.php HTTP/1.1" 404 345
198.51.100.2 - - [12/Oct/2026:10:00:11 +0000] "GET /wp-admin HTTP/1.1" 404 345
198.51.100.2 - - [12/Oct/2026:10:00:12 +0000] "GET /xmlrpc.php HTTP/1.1" 404 345
EOF
        echo "Log de exemplo criado em $arquivo"
    fi

    [[ -r "$arquivo" ]] || die "sem permissão de leitura no arquivo de log: $arquivo" 1

    echo "=== Top $top_n IPs com mais requisições ==="
    echo "Arquivo: $arquivo"
    echo

    # Pipeline clássico: extrai IP ($1), ordena, conta únicos, ordena por contagem, pega top N
    awk '{print $1}' "$arquivo" | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -"$top_n" | \
        awk '{printf "%3d  %s\n", $1, $2}'

    echo
    echo "=== Top $top_n IPs com erros 4xx/5xx ==="
    awk '$9 ~ /^[45]/ {print $1}' "$arquivo" | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -"$top_n" | \
        awk '{printf "%3d  %s\n", $1, $2}'

    log_info "fim"
}

main "$@"