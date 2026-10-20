#!/usr/bin/env bash
#
# checa-deps.sh - verifica dependências de um sistema ou aplicação.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   checa-deps.sh [ARQUIVO_DE_DEPENDENCIAS]
#
# Opções:
#   -h, --help     Exibe esta ajuda
#   -v, --verbose  Modo verboso
#   -n, --dry-run  Simula execução
#
# Códigos de saída:
#   0  Todas as dependências satisfeitas
#   1  Algumas dependências faltando
#   2  Uso incorreto / argumentos inválidos
#   3  Pré-requisito ausente
#   4  Erro de permissão
#
# Exemplo:
#   checa-deps.sh dependencias.txt
#
# Dependências:
#   - bash 4+
#
# =============================================================================

set -Eeuo pipefail

# Arquivo de dependências (padrão: dependencias.txt no diretório atual)
DEPS_FILE="${1:-dependencias.txt}"

if [[ ! -f "$DEPS_FILE" ]]; then
    # Se arquivo não existe, cria exemplo
    if [[ ! -w "$(pwd)" ]]; then
        echo "ERRO: Não é possível criar arquivo de exemplo em $(pwd)" >&2
        exit 4
    fi
    cat > "$DEPS_FILE" << 'EOF'
# Dependências do sistema (uma por linha)
# Comentários começam com #
# Linhas vazias são ignoradas
curl
wget
git
jq
docker
python3
EOF
    echo "Arquivo de exemplo criado: $DEPS_FILE"
    echo "Editado com suas dependências reais e execute novamente."
    exit 0
fi

missing=0
while IFS= read -r dep || [[ -n "$dep" ]]; do
    # Remove espaços em branco
    dep="$(echo -n "$dep" | xargs)"
    
    # Ignora vazios e comentários
    [[ -z "$dep" ]] && continue
    [[ "$dep" =~ ^[[:space:]]*# ]] && continue
    
    if ! command -v "$dep" > /dev/null 2>&1; then
        echo "❌ Dependência faltando: $dep"
        ((missing++))
    else
        echo "✅ Dependência encontrada: $dep"
    fi
done < "$DEPS_FILE"

if [[ $missing -eq 0 ]]; then
    echo "✅ Todas as dependências estão satisfeitas"
    exit 0
else
    echo "❌ $missing dependência(s) faltando"
    exit 1
fi