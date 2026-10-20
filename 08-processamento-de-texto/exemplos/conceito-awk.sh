#!/usr/bin/env bash
# conceito-awk.sh — awk colunas, cálculos, arrays (versão didática)

cat > /tmp/acessos.log << 'EOF'
192.168.1.10 - - [15/Jan/2024] "GET /index.html" 200 1024
192.168.1.20 - - [15/Jan/2024] "POST /api/login" 200 512
192.168.1.10 - - [15/Jan/2024] "GET /dashboard" 200 2048
192.168.1.30 - - [15/Jan/2024] "GET /index.html" 404 256
192.168.1.10 - - [15/Jan/2024] "GET /api/users" 500 128
192.168.1.20 - - [15/Jan/2024] "GET /index.html" 200 1024
EOF

echo "=== Colunas (default FS=espaço) ==="
awk '{print $1, $7, $10}' /tmp/acessos.log

echo
echo "=== FS customizado ==="
awk -F'[ :"]+' '{print $1, $4, $8}' /tmp/acessos.log

echo
echo "=== Filtro + processamento ==="
awk '$9 == 200 {print $1, $7}' /tmp/acessos.log

echo
echo "=== NR (linha), NF (campos) ==="
awk '{print "Linha " NR ": " NF " campos -> IP=" $1}' /tmp/acessos.log

echo
echo "=== Cálculos: soma e média do tamanho (col 10) ==="
awk '{soma += $10} END {print "Total bytes:", soma; print "Média:", soma/NR}' /tmp/acessos.log

echo
echo "=== Arrays associativos: conta requisições por IP ==="
awk '{ip[$1]++} END {for (i in ip) print i, ip[i]}' /tmp/acessos.log

echo
echo "=== Arrays: bytes por IP ==="
awk '{bytes[$1] += $10} END {for (i in bytes) print i, bytes[i]}' /tmp/acessos.log

echo
echo "=== BEGIN/END ==="
awk 'BEGIN {print "=== INÍCIO RELATÓRIO ==="} {print $1} END {print "=== FIM: " NR " linhas ==="}' /tmp/acessos.log

rm /tmp/acessos.log