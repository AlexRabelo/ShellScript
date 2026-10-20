#!/usr/bin/env bash
# valida-ip.sh — Gabarito Exercício 3

[[ $# -ge 1 ]] || { echo "Uso: $0 IP" >&2; exit 2; }

ip="$1"

if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "IP inválido (formato): $ip" >&2
    exit 1
fi

IFS=. read -r o1 o2 o3 o4 <<< "$ip"

for octeto in "$o1" "$o2" "$o3" "$o4"; do
    if (( octeto > 255 )); then
        echo "IP inválido (octeto > 255): $ip" >&2
        exit 1
    fi
done

echo "IP válido: $ip"