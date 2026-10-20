#!/usr/bin/env bash
# compara-agendamento.sh - Compara cron e systemd timers (COM AVISOS SHELLCHECK)

timers=$(systemctl list-timers --all --no-pager)
crons=$(cat /etc/crontab /etc/cron.d/* 2>/dev/null)

echo "Timers ativos:"
echo "$timers" | grep -v "^$" | wc -l

echo "Entradas cron:"
echo "$crons" | grep -v "^#" | grep -v "^$" | wc -l

for timer in $timers; do
  proximo=$(systemctl show $timer --property=NextElapseUSecMonotonic --value)
  echo "Timer: $timer, Próximo: $proximo"
done

if [ $# -eq 1 ]; then
  echo "Argumento: $1"
fi