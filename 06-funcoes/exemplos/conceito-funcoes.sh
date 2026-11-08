#!/usr/bin/env bash
# conceito-funcoes.sh — Definição, args, return, local (versão didática)

echo "=== Definição e chamada ==="
saudacao() {
    echo "Olá, $1!"
}
saudacao "Mundo"
saudacao "Bash"

echo
echo "=== Argumentos: \$1, \$2, \"\$@\" ==="
mostra_args() {
    echo "Total de args: $#"
    for arg in "$@"; do
        echo "  Arg: [$arg]"
    done
}
mostra_args "um" "dois tres" "quatro"

echo
echo "=== Retorno de status (return / último comando) ==="
eh_par() {
    local n="$1"
    (( n % 2 == 0 ))   # retorna 0 se par, 1 se ímpar
}
eh_par 4 && echo "4 é par" || echo "4 é ímpar"
eh_par 5 && echo "5 é par" || echo "5 é ímpar"

echo
echo "=== Return explícito com códigos customizados ==="
classifica() {
    local n="$1"
    if (( n > 0 )); then return 0
    elif (( n < 0 )); then return 1
    else return 2
    fi
}
for n in -5 0 5; do
    classifica "$n"
    case $? in
        0) echo "$n -> positivo (exit 0)" ;;
        1) echo "$n -> negativo (exit 1)" ;;
        2) echo "$n -> zero (exit 2)" ;;
    esac
done

echo
echo "=== Escopo: local vs global ==="
var_global=100
funcao_local() {
    local var_global=0
    var_global=$(( var_global + 1 ))
    echo "Dentro (local): $var_global"
}
funcao_local
echo "Fora (global): $var_global"