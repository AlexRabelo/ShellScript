#!/usr/bin/env bash
#
# classifica-carga.sh - classifica a carga do sistema por core.
#
# Uso: ./classifica-carga.sh

# Lê carga de 1 minuto (primeiro campo de /proc/loadavg)
read -r carga _ < /proc/loadavg
cores=$(nproc)

# Calcula carga por core
carga_por_core=$(awk -v c="$carga" -v n="$cores" 'BEGIN { printf "%.2f", c/n }')

# Classifica
if (( $(awk -v v="$carga_por_core" 'BEGIN { print (v < 0.70) }') )); then
    status="OK"
    codigo=0
elif (( $(awk -v v="$carga_por_core" 'BEGIN { print (v <= 1.00) }') )); then
    status="AVISO"
    codigo=1
else
    status="CRÍTICO"
    codigo=2
fi

echo "Carga: $carga_por_core (por core, $cores cores) - $status"
exit $codigo