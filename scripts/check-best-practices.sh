#!/usr/bin/env bash
# =============================================================================
# check-best-practices.sh — Verifica boas práticas em scripts shell
# =============================================================================
# Uso: ./scripts/check-best-practices.sh
# Exit codes: 0 = OK, 1 = problemas encontrados
# =============================================================================

set -Eeuo pipefail

ERROS=0
AVISOS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

check_file() {
    local file="$1"
    local has_errors=0
    local has_warnings=0

    # 1. Não usar `ls` em loops (usar glob ou find)
    local ls_pattern="for .* in \$(ls"
    if grep -q "$ls_pattern" "$file" 2>/dev/null; then
        echo -e "${RED}❌ $file: uso de 'for x in \$(ls ...)' — use glob 'for x in *' ou find${NC}"
        has_errors=1
    fi

    # 2. read sem -r
    if grep -q '^ *read [^ -]' "$file" 2>/dev/null; then
        if ! grep -q 'read -r' "$file"; then
            echo -e "${YELLOW}⚠️  $file: 'read' sem flag '-r' (pode interpretar backslashes)${NC}"
            has_warnings=1
        fi
    fi

    # 3. Variáveis não quoted em expansão
    # Verifica padrões problemáticos (simplificado)
    if grep -Eq '\$[A-Za-z_][A-Za-z0-9_]*[^"]' "$file" 2>/dev/null; then
        # Pode ser falso positivo, apenas warning se não há aspas óbvias
        :
    fi

    # 4. Uso de `[[ ]]` vs `[ ]`
    if grep -q '^ *\[ ' "$file" && ! grep -q '^ *\[\[ ' "$file"; then
        echo -e "${YELLOW}⚠️  $file: usa '[ ]' mas não '[[ ]]' — prefira [[ ]] em Bash${NC}"
        has_warnings=1
    fi

    # 5. Aritmética com `(( ))` vs `expr` ou `$[]`
    if grep -q '\$\[.*\]' "$file" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  $file: usa '\$[...]' aritmética antiga — use '(( ... ))'${NC}"
        has_warnings=1
    fi
    if grep -q 'expr ' "$file" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  $file: usa 'expr' — use '(( ... ))' para aritmética${NC}"
        has_warnings=1
    fi

    # 6. Funções sem local
    if grep -q '^[a-z_][a-z0-9_]*() {' "$file" 2>/dev/null; then
        if ! grep -A5 '^[a-z_][a-z0-9_]*() {' "$file" | grep -q 'local '; then
            echo -e "${YELLOW}⚠️  $file: funções sem variáveis 'local' (risco de vazamento)${NC}"
            has_warnings=1
        fi
    fi

    # 7. Trap EXIT para limpeza (em scripts de produção)
    if grep -q 'mktemp\|TMPDIR\|lock' "$file" 2>/dev/null; then
        if ! grep -q 'trap.*EXIT' "$file"; then
            echo -e "${YELLOW}⚠️  $file: usa temp/lock mas sem 'trap cleanup EXIT'${NC}"
            has_warnings=1
        fi
    fi

    # 8. getopts vs parsing manual
    local case_pattern="case \$1 in"
    if grep -q "$case_pattern" "$file" && ! grep -q 'getopts' "$file"; then
        echo -e "${YELLOW}⚠️  $file: parsing manual de flags — use 'getopts'${NC}"
        has_warnings=1
    fi

    # 9. Hardcoded paths que deveriam ser variáveis
    if grep -q '/tmp/[a-z]' "$file" && ! grep -q 'mktemp' "$file"; then
        echo -e "${YELLOW}⚠️  $file: caminho hardcoded em /tmp — use 'mktemp'${NC}"
        has_warnings=1
    fi

    # 10. Exit codes não documentados no header
    if grep -q 'exit [0-9]' "$file"; then
        local exit_codes
        exit_codes=$(grep -o 'exit [0-9]*' "$file" | sed 's/exit //' | sort -u)
        for code in $exit_codes; do
            if ! head -30 "$file" | grep -q "exit.*$code"; then
                echo -e "${YELLOW}⚠️  $file: exit code $code usado mas não documentado no header${NC}"
                has_warnings=1
            fi
        done
    fi

    if [[ $has_errors -eq 1 ]]; then
        ERROS=$((ERROS + 1))
    fi
    AVISOS=$((AVISOS + has_warnings))
}

echo "🔍 Verificando boas práticas de shell script..."
echo ""

while IFS= read -r -d '' file; do
    check_file "$file"
done < <(find . -name "*.sh" -not -path "./.git/*" -not -path "./.github/*" -not -path "./assessment/*" -print0)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $ERROS -eq 0 && $AVISOS -eq 0 ]]; then
    echo -e "${GREEN}✅ Boas práticas OK ($ERROS erros, $AVISOS avisos)${NC}"
    exit 0
elif [[ $ERROS -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  Boas práticas OK com $AVISOS avisos${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERROS erro(s) e $AVISOS aviso(s)${NC}"
    exit 1
fi