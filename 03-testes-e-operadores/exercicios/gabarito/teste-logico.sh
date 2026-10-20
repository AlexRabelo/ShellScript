#!/usr/bin/env bash
# teste-logico.sh — Gabarito Exercício 4

mem=85
cpu=60
disco=95

# CRÍTICO: (mem > 90 OU disco > 90) E cpu > 50
if (( (mem > 90 || disco > 90) && cpu > 50 )); then
    echo "CRÍTICO"
# ATENÇÃO: mem > 80 OU disco > 80
elif (( mem > 80 || disco > 80 )); then
    echo "ATENÇÃO"
else
    echo "OK"
fi