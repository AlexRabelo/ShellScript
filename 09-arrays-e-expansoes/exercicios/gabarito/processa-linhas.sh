#!/usr/bin/env bash
# processa-linhas.sh — Gabarito Exercício 5

mapfile -t linhas < /etc/passwd

declare -A shells
for linha in "${linhas[@]}"; do
    IFS=: read -r user _ _ _ _ _ shell <<< "$linha"
    (( shells[$shell]++ ))
done

for sh in "${!shells[@]}"; do
    echo "$sh: ${shells[$sh]}"
done | sort -k2 -nr