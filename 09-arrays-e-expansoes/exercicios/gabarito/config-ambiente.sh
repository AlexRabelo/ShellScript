#!/usr/bin/env bash
# config-ambiente.sh — Gabarito Exercício 3

[[ $# -ge 1 ]] || { echo "Uso: $0 AMBIENTE" >&2; exit 2; }

amb="$1"

declare -A config=( ["dev"]="debug:true,port:8080" ["prod"]="debug:false,port:443" ["homolog"]="debug:false,port:8443" )

[[ -n "${config[$amb]}" ]] || { echo "Ambiente inválido: $amb" >&2; exit 2; }

IFS=',' read -r d p <<< "${config[$amb]}"
debug="${d#*:}"
porta="${p#*:}"

echo "Ambiente: $amb, Debug: $debug, Porta: $porta"