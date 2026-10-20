#!/usr/bin/env bash
#
# ferramenta-cli.sh - CLI completo com getopts e validações.
#
# Uso: sudo ./ferramenta-cli.sh -u USUARIO [-g GRUPO] [-s SHELL] [-v] [-f] [--dry-run] [-h]

set -Eeuo pipefail

readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/valida.sh"

USUARIO=""
GRUPO=""
SHELL_USER="/bin/bash"
VERBOSE=0
FORCAR=0
DRY_RUN=0

uso() {
    cat << EOF
ferramenta-cli.sh - Gerenciamento de usuários via CLI

Uso: $(basename "$0") -u USUARIO [OPÇÕES]

Obrigatório:
  -u USUARIO    Nome do usuário (alfanumérico)

Opções:
  -g GRUPO      Grupo principal (padrão: usuários)
  -s SHELL      Shell de login (padrão: /bin/bash)
  -v            Verboso
  -f            Força (sobrescreve se existir)
  --dry-run     Simula sem alterar
  -h            Esta ajuda
EOF
}

valida_usuario() {
    [[ "$USUARIO" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Usuário inválido: '$USUARIO' (use a-z, 0-9, _, -)" 2
}

valida_grupo() {
    if [[ -n "$GRUPO" ]]; then
        getent group "$GRUPO" >/dev/null || die "Grupo '$GRUPO' não existe" 3
    fi
}

valida_shell() {
    if [[ -n "$SHELL_USER" ]]; then
        grep -qx "$SHELL_USER" /etc/shells || die "Shell '$SHELL_USER' não está em /etc/shells" 3
    fi
}

executa() {
    if (( DRY_RUN )); then
        log_aviso "[DRY-RUN] $*"
    else
        log_info "EXEC: $*"
        "$@"
    fi
}

main() {
    # getopts
    while getopts ':u:g:s:vfh' opt; do
        case "$opt" in
            u) USUARIO="$OPTARG" ;;
            g) GRUPO="$OPTARG" ;;
            s) SHELL_USER="$OPTARG" ;;
            v) VERBOSE=1 ;;
            f) FORCAR=1 ;;
            h) uso; exit 0 ;;
            :) die "Opção -$OPTARG requer argumento" 2 ;;
            \?) die "Opção inválida: -$OPTARG" 2 ;;
        esac
    done

    shift $((OPTIND - 1))
    for arg in "$@"; do
        case "$arg" in
            --dry-run) DRY_RUN=1 ;;
            *) die "Argumento desconhecido: $arg" 2 ;;
        esac
    done

    (( VERBOSE )) && set -x

    # Requer root
    tem_root || die "Requer root" 1

    # Validações
    [[ -n "$USUARIO" ]] || die "Usuário (-u) obrigatório" 2
    valida_usuario
    valida_grupo
    valida_shell

    # Verifica se usuário existe
    if id "$USUARIO" >/dev/null 2>&1; then
        if (( FORCAR )); then
            log_aviso "Usuário '$USUARIO' existe. Forçando atualização..."
            executa usermod -s "$SHELL_USER" "${GRUPO:+-g $GRUPO}" "$USUARIO"
            log_sucesso "Usuário atualizado"
        else
            log_erro "Usuário '$USUARIO' já existe. Use -f para forçar." 4
        fi
    else
        log_info "Criando usuário '$USUARIO'..."
        executa useradd -m -s "$SHELL_USER" "${GRUPO:+-g $GRUPO}" "$USUARIO"
        log_sucesso "Usuário criado"
    fi
}

trap 'log_erro "Interrompido"; exit 130' INT
trap 'log_erro "Erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

main "$@"