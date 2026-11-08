#!/usr/bin/env bash
#
# idempotente-usuario.sh - cria/atualiza usuário de forma idempotente.
#
# Uso: sudo ./idempotente-usuario.sh USUARIO [SHELL] [GRUPOS_CSV]

set -Eeuo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/valida.sh"

USUARIO="${1:-}"
SHELL_USER="${2:-/bin/bash}"
GRUPOS="${3:-}"

[[ -n "$USUARIO" ]] || die "Uso: $0 USUARIO [SHELL] [GRUPOS_CSV]" 2
tem_root || die "Requer root" 1

# Verifica se usuário existe
if id "$USUARIO" >/dev/null 2>&1; then
    log_info "Usuário '$USUARIO' já existe. Verificando configurações..."

    # Atualiza shell se diferente
    shell_atual=$(getent passwd "$USUARIO" | cut -d: -f7)
    if [[ "$shell_atual" != "$SHELL_USER" ]]; then
        usermod -s "$SHELL_USER" "$USUARIO"
        log_sucesso "Shell atualizado para $SHELL_USER"
    else
        log_info "Shell já é $SHELL_USER"
    fi

    # Atualiza grupos se fornecidos
    if [[ -n "$GRUPOS" ]]; then
        usermod -G "$GRUPOS" "$USUARIO"
        log_sucesso "Grupos atualizados: $GRUPOS"
    fi

    log_sucesso "Usuário '$USUARIO' já configurado corretamente"
else
    log_info "Criando usuário '$USUARIO'..."
    if [[ -n "$GRUPOS" ]]; then
        useradd -m -s "$SHELL_USER" -G "$GRUPOS" "$USUARIO"
    else
        useradd -m -s "$SHELL_USER" "$USUARIO"
    fi
    log_sucesso "Usuário '$USUARIO' criado com shell $SHELL_USER"
fi

exit 0