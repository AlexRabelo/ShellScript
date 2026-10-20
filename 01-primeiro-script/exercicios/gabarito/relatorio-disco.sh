#!/usr/bin/env bash
#
# relatorio-disco.sh - mostra o uso de disco e o tamanho de /var/log.

echo "=== Relatório de disco ==="
echo
df -h
echo
echo "Tamanho de /var/log:"
du -sh /var/log 2> /dev/null
