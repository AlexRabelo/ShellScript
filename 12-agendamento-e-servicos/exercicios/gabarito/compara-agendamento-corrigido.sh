#!/usr/bin/env bash
# compara-agendamento.sh - Compara cron e systemd timers
#
# Uso:
#   compara-agendamento.sh [argumento]
#
# Exibe contagem de timers ativos e entradas cron

set -Eeuo pipefail

timers_output=$(systemctl list-timers --all --no-pager 2>/dev/null || true)
crons_output=$(cat /etc/crontab /etc/cron.d/* 2>/dev/null || true)

echo "Timers ativos:"
timers_count=$(echo "$timers_output" | grep -v "^$" | wc -l)
echo "$timers_count"

echo "Entradas cron:"
crons_count=$(echo "$crons_output" | grep -v "^#" | grep -v "^$" | wc -l)
echo "$crons_count"

while IFS= read -r timer_line; do
    [[ -z "$timer_line" || "$timer_line" == "UNIT"* ]] && continue
    timer=$(echo "$timer_line" | awk '{print $1}')
    proximo=$(systemctl show "$timer" --property=NextElapseUSecMonotonic --value 2>/dev/null || echo "n/a")
    echo "Timer: $timer, Próximo: $proximo"
done <<< "$timers_output"

if [[ $# -eq 1 ]]; then
    echo "Argumento: $1"
fi