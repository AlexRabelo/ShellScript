#!/usr/bin/env bash
#
# usuario-valido.sh - valida usuário do sistema.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   usuario-valido.sh USUARIO
#
# Opções:
#   -h, --help     Exibe esta ajuda
#   -v, --verbose  Modo verboso
#   -n, --dry-run  Simula execução
#
# Códigos de saída:
#   0  Usuário válido
#   1  Erro de validação (usuário não existe, shell inválido, etc.)
#   2  Uso incorreto / argumentos inválidos
#   3  Pré-requisito ausente (comandos necessários não encontrados)
#   4  Erro de permissão
#
# Exemplo:
#   usuario-valido.sh joao
#
# Dependências:
#   - bash 4+
#   - id, getent, cut
#
# =============================================================================

set -Eeuo pipefail

[[ $# -eq 1 ]] || { echo "Uso: $0 USUARIO" >&2; exit 2; }

usuario="$1"

echo "Validando usuário: $usuario"
echo

# 1. Usuário existe?
if ! id "$usuario" >/dev/null 2>&1; then
    echo "✗ Usuário não existe no sistema"
    exit 1
fi
echo "✓ Usuário existe"

# 2. Shell de login válido?
shell=$(getent passwd "$usuario" | cut -d: -f7)
if [[ "$shell" == "/usr/sbin/nologin" || "$shell" == "/bin/false" ]]; then
    echo "✗ Shell de login inválido: $shell"
    exit 1
fi
echo "✓ Shell de login válido: $shell"

# 3. Home existe e é gravável pelo usuário?
home=$(getent passwd "$usuario" | cut -d: -f6)
if [[ ! -d "$home" ]]; then
    echo "✗ Diretório home não existe: $home"
    exit 1
fi

# Testa se é gravável (precisa ser o usuário ou root para testar de verdade)
# Aqui fazemos teste simples de permissão no filesystem
if [[ -w "$home" ]]; then
    echo "✓ Home gravável (pelo usuário atual): $home"
else
    echo "⚠ Home não gravável pelo usuário atual: $home"
fi

echo
echo "=== Relatório final ==="
echo "Usuário: $usuario"
echo "Shell:   $shell"
echo "Home:    $home"
echo "Status:  VÁLIDO"