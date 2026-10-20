#!/usr/bin/env bash
# sanitiza.sh — Gabarito Exercício 2

[[ $# -ge 1 ]] || { echo "Uso: $0 STRING" >&2; exit 2; }

s="$1"

# Remove espaços início/fim
s="${s## }"   # remove espaços do início
s="${s%% }"   # remove espaços do fim
# ou: s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"  # mais robusto

# Minúsculas
s="${s,,}"

# @ -> _at_
s="${s//@/_at_}"

echo "$s"