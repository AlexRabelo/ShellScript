#!/usr/bin/env bash
# teste-numerico.sh — Gabarito Exercício 2

cpu=75
limite=80

(( cpu > limite )) && echo "cpu > limite: SIM" || echo "cpu > limite: NÃO"
(( cpu >= limite )) && echo "cpu >= limite: SIM" || echo "cpu >= limite: NÃO"
(( cpu < limite )) && echo "cpu < limite: SIM" || echo "cpu < limite: NÃO"
(( cpu <= limite )) && echo "cpu <= limite: SIM" || echo "cpu <= limite: NÃO"

if (( cpu > limite )); then
    echo "ALERTA"
else
    echo "OK"
fi

(( cpu++ ))
echo "Depois de cpu++: cpu=$cpu"
(( cpu > limite )) && echo "Agora: ALERTA" || echo "Agora: OK"