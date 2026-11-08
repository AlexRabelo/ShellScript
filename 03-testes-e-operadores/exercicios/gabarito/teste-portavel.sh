#!/usr/bin/env bash
#
# teste-portavel.sh - demonstra diferenças entre [[ ]] e [ ].
#
# Uso: ./teste-portavel.sh

echo "=== 1. Variável VAZIA ==="
vazio=""

echo "Com [[ ]]:"
if [[ $vazio == "" ]]; then echo "  [[ \$vazio == \"\"]] -> TRUE"; else echo "  FALSE"; fi

echo "Com [ ] (sem aspas - QUEBRA):"
if [ $vazio == "" ]; then echo "  [ \$vazio == \"\"]] -> TRUE"; else echo "  FALSE"; fi
# Isso falha: [ == "" ] -> erro de sintaxe

echo "Com [ ] (com aspas - funciona):"
if [ "$vazio" == "" ]; then echo "  [ \"\$vazio\" == \"\"]] -> TRUE"; else echo "  FALSE"; fi

echo
echo "=== 2. Variável COM ESPAÇOS ==="
com_espacos="ola mundo"

echo "Com [[ ]]:"
if [[ $com_espacos == "ola mundo" ]]; then echo "  [[ \$com_espacos == \"ola mundo\" ]] -> TRUE"; fi

echo "Com [ ] (sem aspas - QUEBRA):"
# if [ $com_espacos == "ola mundo" ]; then ...
# Isso falha: [ ola mundo == "ola mundo" ] -> too many arguments
echo "  [ \$com_espacos == \"ola mundo\" ] -> ERRO: too many arguments"

echo "Com [ ] (com aspas - funciona):"
if [ "$com_espacos" == "ola mundo" ]; then echo "  [ \"\$com_espacos\" == \"ola mundo\" ]] -> TRUE"; fi

echo
echo "=== 3. OPERADORES < e > (REDIR ACIDENTAL) ==="
a=5
b=10

echo "Com (( )) - correto:"
if (( a < b )); then echo "  (( 5 < 10 )) -> TRUE (5 é menor)"; fi

echo "Com [[ ]] - correto:"
if [[ $a -lt $b ]]; then echo "  [[ 5 -lt 10 ]] -> TRUE"; fi

echo "Com [ ] - PERIGO:"
echo "  [ 5 < 10 ] NÃO compara números!"
echo "  Cria arquivo chamado '10' vazio no diretório atual!"
echo "  Código de saída 0 (sucesso do redirecionamento), não comparação!"

# Demonstra o perigo (comentado para não sujar o diretório)
# [ 5 < 10 ] && echo "  Isso NÃO é comparação!"

echo
echo "=== 4. REGEX COM =~ ==="
num="12345"

echo "Com [[ ]] (funciona):"
if [[ $num =~ ^[0-9]+$ ]]; then echo "  [[ \$num =~ ^[0-9]+\$ ]] -> TRUE"; fi

echo "Com [ ] (NÃO suporta =~):"
echo "  [ ] não tem operador =~"

echo
echo "=== 5. PADRÕES (CURINGAS) ==="
arquivo="script.sh"

echo "Com [[ ]] (funciona):"
if [[ $arquivo == *.sh ]]; then echo "  [[ \$arquivo == *.sh ]] -> TRUE"; fi

echo "Com [ ] (NÃO suporta padrões):"
echo "  [ ] não suporta curingas no lado direito de =="

echo
echo "=== 6. OPERADORES LÓGICOS ==="

echo "Com [[ ]] (&& || !):"
if [[ 1 -eq 1 && 2 -eq 2 ]]; then echo "  [[ 1 -eq 1 && 2 -eq 2 ]] -> TRUE"; fi

echo "Com [ ] (-a -o):"
if [ 1 -eq 1 -a 2 -eq 2 ]; then echo "  [ 1 -eq 1 -a 2 -eq 2 ]] -> TRUE"; fi
echo "  Mas -a e -o são OBSOLETOS e instáveis!"

echo
echo "=== CONCLUSÃO ==="
echo "SEMPRE use [[ ]] em Bash:"
echo "  - Não quebra com variáveis vazias"
echo "  - Não quebra com espaços"
echo "  - Não faz redirecionamento acidental"
echo "  - Suporta =~ (regex) e padrões (curingas)"
echo "  - && || ! são claros e seguros"
echo
echo "[ ] só em scripts POSIX sh estrito (#!/bin/sh)"