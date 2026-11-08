#!/usr/bin/env bash
# debug-condicional.sh — Gabarito Exercício 6

echo "=== Problema 1: [[ \"10\" > \"2\" ]] — comparação LEXICOGRÁFICA ==="
# shellcheck disable=SC2071,SC2050
if [[ "10" > "2" ]]; then
    echo "Resultado: '10' > '2' é VERDADEIRO (lexicográfico: '1' < '2')"
else
    echo "Resultado: '10' > '2' é FALSO"
fi
echo "Explicação: strings comparam caractere a caractere. '1' vem antes de '2'."

echo
echo "=== Correção: comparação NUMÉRICA ==="
# shellcheck disable=SC2050
if (( 10 > 2 )); then
    echo "(( 10 > 2 )): VERDADEIRO (numérico correto)"
fi

echo
echo "=== Problema 2: [ 10 > 2 ] — REDIRECIONAMENTO! ==="
echo "O comando [ 10 > 2 ] cria/limpa um arquivo chamado '2' com conteúdo '10'"
echo "Testando (não execute isso em diretório importante):"
# [ 10 > 2 ]  # COMENTADO para não criar arquivo lixo
echo "  \$? depois de [ 10 > 2 ]: sempre 0 (sucesso do redirecionamento)"

echo
echo "=== Correção em [ ]: usar -gt ==="
# shellcheck disable=SC2050
if [ 10 -gt 2 ]; then
    echo "[ 10 -gt 2 ]: VERDADEIRO (numérico correto em [ ])"
fi