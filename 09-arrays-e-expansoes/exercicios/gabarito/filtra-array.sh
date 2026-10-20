#!/usr/bin/env bash
# filtra-array.sh — Gabarito Exercício 6

ips=("10.0.1.1" "10.0.2.2" "192.168.1.1" "10.0.3.3" "172.16.1.1")
privados=()

for ip in "${ips[@]}"; do
    case "$ip" in
        10.*) privados+=("$ip") ;;
        172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) privados+=("$ip") ;;
        192.168.*) privados+=("$ip") ;;
    esac
done

for ip in "${privados[@]}"; do
    echo "$ip"
done

declare -p privados