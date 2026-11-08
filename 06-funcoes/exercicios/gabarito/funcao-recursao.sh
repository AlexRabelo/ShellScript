#!/usr/bin/env bash
# funcao-recursao.sh — Gabarito Exercício 5

fatorial_rec() {
    local n="$1"
    (( n <= 1 )) && { echo 1; return; }
    echo $(( n * $(fatorial_rec $((n - 1))) ))
}

fatorial_iter() {
    local n="$1"
    local res=1
    for (( i=2; i<=n; i++ )); do
        res=$(( res * i ))
    done
    echo $res
}

for n in {0..10}; do
    r1=$(fatorial_rec $n)
    r2=$(fatorial_iter $n)
    [[ $r1 -eq $r2 ]] && ok="OK" || ok="DIFERENTE!"
    echo "$n! = $r1 (rec) vs $r2 (iter) -> $ok"
done