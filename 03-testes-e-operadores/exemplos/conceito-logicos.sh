#!/usr/bin/env bash
# conceito-logicos.sh — Operadores lógicos e precedência (versão didática)

a=10
b=5
c=15

echo "=== E (&&) — ambos devem ser verdadeiros ==="
[[ $a -gt $b && $a -lt $c ]] && echo "a > b E a < c: VERDADEIRO"
[[ $a -gt $b && $a -gt $c ]] || echo "a > b E a > c: FALSO"

echo
echo "=== OU (||) — pelo menos um verdadeiro ==="
[[ $a -lt $b || $a -lt $c ]] && echo "a < b OU a < c: VERDADEIRO"
[[ $a -gt $c || $b -gt $c ]] || echo "a > c OU b > c: FALSO"

echo
echo "=== NÃO (!) — inverte ==="
[[ ! $a -lt $b ]] && echo "NÃO (a < b): VERDADEIRO (pois a > b)"

echo
echo "=== Precedência: && antes de || ==="
# [[ A || B && C ]] = [[ A || (B && C) ]]
[[ 0 -eq 1 || 5 -gt 3 && 10 -gt 5 ]] && echo "0=1 OU (5>3 E 10>5): VERDADEIRO"

echo
echo "=== Parênteses forçam ordem: (A || B) && C ==="
[[ ( 0 -eq 1 || 5 -gt 3 ) && 10 -gt 5 ]] && echo "(0=1 OU 5>3) E 10>5: VERDADEIRO"

echo
echo "=== Comando composto: if com múltiplas condições ==="
arquivo="/etc/passwd"
if [[ -f "$arquivo" && -r "$arquivo" ]]; then
    echo "$arquivo existe E é legível"
fi

# Erro comum: -a/-o dentro de [ ] — EVITE
# [ -f "$arquivo" -a -r "$arquivo" ]  # funciona mas propenso a erro
# Prefira dois testes separados:
if [[ -f "$arquivo" ]] && [[ -r "$arquivo" ]]; then
    echo "Dois [[ ]] com && fora: também funciona"
fi