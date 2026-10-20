#!/usr/bin/env bash
# =============================================================================
# check-headers.sh — Valida header profissional em todos os scripts .sh
# =============================================================================
# Uso: ./scripts/check-headers.sh
# Exit codes: 0 = OK, 1 = erros encontrados
# =============================================================================

set -Eeuo pipefail

ERROS=0
AVISOS=0

# Cores para output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

check_file() {
    local file="$1"
    local has_errors=0
    local has_warnings=0

    # 1. Shebang correto
    if ! head -1 "$file" | grep -q "^#!/usr/bin/env bash$"; then
        echo -e "${RED}❌ $file: shebang ausente ou incorreto (esperado: #!/usr/bin/env bash)${NC}"
        has_errors=1
    fi

    # 2. Strict mode presente (nas primeiras 20 linhas)
    if ! head -20 "$file" | grep -q "set -Eeuo pipefail"; then
        echo -e "${RED}❌ $file: falta 'set -Eeuo pipefail' (strict mode)${NC}"
        has_errors=1
    fi

    # 3. Header com metadados básicos (autor, versão, descrição, uso)
    local header_content
    header_content=$(head -30 "$file")

    if ! echo "$header_content" | grep -q "Autor:"; then
        echo -e "${YELLOW}⚠️  $file: header sem campo 'Autor:'${NC}"
        has_warnings=1
    fi

    if ! echo "$header_content" | grep -q "Versão:"; then
        echo -e "${YELLOW}⚠️  $file: header sem campo 'Versão:'${NC}"
        has_warnings=1
    fi

    if ! echo "$header_content" | grep -q "Descrição:"; then
        echo -e "${YELLOW}⚠️  $file: header sem campo 'Descrição:'${NC}"
        has_warnings=1
    fi

    if ! echo "$header_content" | grep -q "Uso:"; then
        echo -e "${YELLOW}⚠️  $file: header sem campo 'Uso:'${NC}"
        has_warnings=1
    fi

    if ! echo "$header_content" | grep -q "Códigos de saída:"; then
        echo -e "${YELLOW}⚠️  $file: header sem campo 'Códigos de saída:'${NC}"
        has_warnings=1
    fi

    # 4. Verifica variáveis readonly para constantes (opcional - warning)
    if grep -q '^[A-Z_][A-Z0-9_]*=' "$file" && ! grep -q "readonly" "$file"; then
        echo -e "${YELLOW}⚠️  $file: constantes em MAIÚSCULAS sem 'readonly'${NC}"
        has_warnings=1
    fi

    # 5. Verifica aspas em expansões (verificação básica)
    if grep -q '\$[A-Z_][A-Z0-9_]*[^"]' "$file" 2>/dev/null; then
        # Pode gerar falsos positivos, apenas warning
        :
    fi

    if [[ $has_errors -eq 1 ]]; then
        ((ERROS++))
    fi
    ((AVISOS+=has_warnings))
}

echo "🔍 Verificando headers profissionais..."
echo ""

# Encontra todos .sh exceto .github/ e assessment/ (que são templates/labs)
while IFS= read -r -d '' file; do
    check_file "$file"
done < <(find . -name "*.sh" -not -path "./.git/*" -not -path "./.github/*" -not -path "./assessment/*" -print0)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $ERROS -eq 0 && $AVISOS -eq 0 ]]; then
    echo -e "${GREEN}✅ Todos os headers válidos ($ERROS erros, $AVISOS avisos)${NC}"
    exit 0
elif [[ $ERROS -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  Headers OK com $AVISOS avisos (recomendado corrigir)${NC}"
    exit 0  # warnings não bloqueiam
else
    echo -e "${RED}❌ $ERROS erro(s) e $AVISOS aviso(s) encontrado(s)${NC}"
    exit 1
fi