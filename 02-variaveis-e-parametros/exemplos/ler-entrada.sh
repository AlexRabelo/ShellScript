#!/usr/bin/env bash
#
# ler-entrada.sh - Demonstra o comando read com várias opções
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   ler-entrada.sh
#
# Códigos de saída:
#   0  Sucesso
#
# Exemplos:
#   ./ler-entrada.sh
#
# Demonstra:
#   - read -rp (prompt)
#   - read -s (silencioso/senha)
#   - read -t (timeout)
#   - read -r (raw, preserva barras)
#   - read múltiplas variáveis
#   - while IFS= read -r (padrão seguro para arquivos)
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

    echo "=== Demonstração do read ==="
    echo

    # 1. Leitura simples com prompt
    if [[ "$DRY_RUN" -eq 0 ]]; then
        read -rp "Digite seu nome: " nome
        echo "Olá, $nome!"
    else
        log_info "[DRY-RUN] read -rp 'Digite seu nome: ' nome"
    fi
    echo

    # 2. Leitura silenciosa (senha)
    if [[ "$DRY_RUN" -eq 0 ]]; then
        read -sp "Digite uma senha (não será exibida): " senha
        echo   # pula linha após read -s
        echo "Senha lida (tamanho: ${#senha} caracteres)"
    else
        log_info "[DRY-RUN] read -sp 'Digite uma senha...' senha"
    fi
    echo

    # 3. Leitura com timeout
    echo "Você tem 3 segundos para digitar algo:"
    if [[ "$DRY_RUN" -eq 0 ]]; then
        if read -t 3 -p "> " resposta; then
            echo "Você digitou: $resposta"
        else
            echo "Tempo esgotado!"
        fi
    else
        log_info "[DRY-RUN] read -t 3 -p '> ' resposta"
    fi
    echo

    # 4. Leitura raw (preserva barras invertidas)
    echo "Digite um caminho com barras (ex: C:\\Users\\Nome):"
    if [[ "$DRY_RUN" -eq 0 ]]; then
        read -r caminho
        echo "Com -r: $caminho"
    else
        log_info "[DRY-RUN] read -r caminho"
    fi
    echo

    # 5. Leitura de múltiplas variáveis
    if [[ "$DRY_RUN" -eq 0 ]]; then
        read -rp "Digite dois números separados por espaço: " num1 num2
        echo "Número 1: $num1"
        echo "Número 2: $num2"
        echo "Soma: $(( num1 + num2 ))"
    else
        log_info "[DRY-RUN] read -rp 'Digite dois números...' num1 num2"
    fi
    echo

    # 6. Leitura em laço (padrão seguro com IFS= e -r)
    echo "=== Lendo arquivo linha a linha ==="
    arquivo="/etc/passwd"
    echo "Primeiras 3 linhas de $arquivo:"
    contador=0
    while IFS= read -r linha; do
        echo "  $linha"
        (( contador++ ))
        [[ $contador -eq 3 ]] && break
    done < "$arquivo"

    log_info "fim"
}

main "$@"