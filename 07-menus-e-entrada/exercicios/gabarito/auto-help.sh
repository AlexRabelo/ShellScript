#!/usr/bin/env bash
#
# auto-help.sh - demonstra sistema de ajuda automática.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   auto-help.sh [COMANDO]
#
# Opções:
#   -h, --help     Exibe esta ajuda
#   -v, --verbose  Modo verboso
#   -n, --dry-run  Simula execução
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto / argumentos inválidos
#   3  Pré-requisito ausente
#   4  Erro de permissão
#
# Exemplo:
#   auto-help.sh saudacao
#
# Dependências:
#   - bash 4+
#
# =============================================================================

set -Eeuo pipefail

# Diretório onde estão os scripts (padrão: diretório atual)
SCRIPT_DIR="${BATS_TEST_DIRNAME:-$(dirname "${BASH_SOURCE[0]}")}"

# Se nenhum argumento fornecido, lista todos os scripts disponíveis
if [[ $# -eq 0 ]]; then
    echo "Scripts disponíveis para ajuda:"
    echo "-------------------------------"
    for script in "$SCRIPT_DIR"/*.sh; do
        [[ -f "$script" ]] || continue
        nome_script="$(basename "$script" .sh)"
        # Tenta extrair descrição do cabeçalho
        descricao=$(head -5 "$script" | grep -E "^# .* -" | sed 's/^# //' | head -1)
        [[ -z "$descricao" ]] && descricao="Sem descrição disponível"
        printf "  %-15s %s\n" "$nome_script" "$descricao"
    done
    exit 0
fi

# Mostra ajuda para o script especificado
script_name="$1"
script_path="$SCRIPT_DIR/$script_name.sh"

if [[ ! -f "$script_path" ]]; then
    echo "Erro: Script '$script_name.sh' não encontrado em $SCRIPT_DIR" >&2
    echo "Use '$0' sem argumentos para ver a lista de scripts disponíveis" >&2
    exit 2
fi

# Extrai e exibe o cabeçalho de comentários (linhas que começam com #)
echo "Ajuda para: $script_name.sh"
echo "============================"
sed -n '/^#/q;p' "$script_path" | sed 's/^# //' | sed '/^$/q'
if [[ -z "$(sed -n '/^#/q;p' "$script_path" | sed 's/^# //' | sed '/^$/q')" ]]; then
    # Se não houver cabeçalho, mostra as primeiras linhas do script
    head -10 "$script_path"
fi