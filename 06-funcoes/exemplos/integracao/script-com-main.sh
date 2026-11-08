#!/usr/bin/env bash
#
# script-com-main.sh - estrutura padrão corporativa com main e bibliotecas.
# Demonstra: modo estrito, importação de lib, getopts, main, trap.
#
# Uso: ./script-com-main.sh -n NOME -v -h

# --- Modo Estrito ---
set -Eeuo pipefail

# --- Descoberta do diretório do script (para importar libs) ---
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="${0##*/}"

# --- Importa Bibliotecas ---
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/valida.sh"

# --- Configuração e Variáveis Globais ---
VERBOSE=0
NOME=""
DRY_RUN=0

# --- Funções Auxiliares ---

uso() {
    cat << EOF
${SCRIPT_NAME} - Script template para infraestrutura

Uso: ${SCRIPT_NAME} [-n NOME] [-v] [--dry-run] [-h]

Opções:
  -n NOME       Nome para saudação (obrigatório)
  -v            Verboso (DEBUG)
  --dry-run     Simula execução sem alterar nada
  -h            Mostra esta ajuda

Exemplos:
  ${SCRIPT_NAME} -n "Servidor Web" -v
  ${SCRIPT_NAME} --dry-run -n "Teste"
EOF
}

valida_entrada() {
    [[ -n "$NOME" ]] || die "Parâmetro -n NOME é obrigatório" 2
    comando_existe date || die "Comando 'date' não encontrado" 3
}

executa_acao() {
    local msg
    msg="Olá, ${NOME}! Script executado em $(date '+%F %T') por $(whoami)@$(hostname_curto)"

    if (( DRY_RUN )); then
        log_aviso "[DRY-RUN] ${msg}"
    else
        log_info "${msg}"
        log_sucesso "Ação concluída com sucesso"
    fi
}

# --- Função Principal ---
main() {
    # Parse de argumentos com getopts (suporta flags curtas e --longas)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n) NOME="${2:-}"; shift 2 ;;
            -v) VERBOSE=1; shift ;;
            --dry-run) DRY_RUN=1; shift ;;
            -h|--help) uso; exit 0 ;;
            *) die "Opção desconhecida: $1" 2 ;;
        esac
    done

    # Configura verbosidade
    (( VERBOSE )) && set -x

    valida_entrada
    executa_acao
}

# --- Tratamento de Sinais ---
trap 'log_erro "Interrompido pelo usuário"; exit 130' INT
trap 'log_erro "Recebido SIGTERM"; exit 143' TERM
trap 'log_erro "Erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Invocação ---
main "$@"