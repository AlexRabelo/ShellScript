#!/usr/bin/env bash
#
# curto-circuito.sh - demonstra o problema do && ||.
#
# Uso: ./curto-circuito.sh

sucesso() {
    echo "  [sucesso] executou, retorna 0"
    return 0
}

falha() {
    echo "  [falha] executou, retorna 1"
    return 1
}

echo "=== Teste 1: sucesso && A || B =="
sucesso && echo "  A" || echo "  B"
echo "Resultado: mostra A (sucesso retorna 0, então A roda, B não)"
echo

echo "=== Teste 2: falha && A || B =="
falha && echo "  A" || echo "  B"
echo "Resultado: mostra B (falha retorna 1, então A não roda, B roda)"
echo

echo "=== Teste 3: sucesso && falha && A || B =="
sucesso && falha && echo "  A" || echo "  B"
echo "Resultado: mostra B!"
echo "Explicação:"
echo "  1. sucesso retorna 0 -> continua"
echo "  2. falha retorna 1 -> PARA o && (curto-circuito)"
echo "  3. O || captura a falha do 'falha' e executa B"
echo "  4. A NUNCA roda!"
echo

echo "=== Por isso NÃO use && || como if-else ==="
echo "Use if/then/else para lógica condicional real."
echo

echo "=== Forma correta com if ==="
if sucesso; then
    if falha; then
        echo "  A"
    else
        echo "  B (falha retornou 1)"
    fi
else
    echo "  B (sucesso retornou != 0)"
fi