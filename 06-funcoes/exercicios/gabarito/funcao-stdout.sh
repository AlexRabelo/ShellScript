#!/usr/bin/env bash
# funcao-stdout.sh — Gabarito Exercício 2

soma() { echo $(( $1 + $2 )); }
sub() { echo $(( $1 - $2 )); }
mul() { echo $(( $1 * $2 )); }
div() {
    (( $2 == 0 )) && { echo "Erro: divisão por zero" >&2; return 1; }
    echo $(( $1 / $2 ))
}

[[ $# -eq 3 ]] || { echo "Uso: $0 NUM1 OP NUM2" >&2; exit 2; }
n1=$1 op=$2 n2=$3

case "$op" in
    +) r=$(soma "$n1" "$n2") ;;
    -) r=$(sub "$n1" "$n2") ;;
    \*) r=$(mul "$n1" "$n2") ;;
    /) r=$(div "$n1" "$n2") || exit 1 ;;
    *) echo "Op inválida: $op" >&2; exit 2 ;;
esac
echo "Resultado: $r"