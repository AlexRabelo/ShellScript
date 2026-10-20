#!/usr/bin/env bash
# armadilha-and-or.sh — Gabarito Exercício 5

falso() { return 1; }

echo "=== Teste 1: true && falso || echo 'executou?' ==="
true && falso || echo "executou?"
# true retorna 0 (sucesso)
# falso executa, retorna 1 (falha)
# como falso falhou, o || executa: "executou?" é impresso

echo
echo "=== Teste 2: if true; then falso; else echo 'else'; fi ==="
if true; then
    falso
else
    echo "else"
fi
# true retorna 0 -> entra no then
# falso executa, retorna 1
# NÃO há else executado (o then foi executado, só o comando dentro falhou)
# Nada é impresso

echo
echo "=== Explicação ==="
echo "A && B || C  NÃO é if-then-else."
echo "Se A=true e B=false, C EXECUTA."
echo "if A; then B; else C; fi  SÓ executa C se A=false."