#!/usr/bin/env bash
# conceito-pipeline.sh — Combinação real: grep | sed | awk (versão didática)

cat > /tmp/acesso.log << 'EOF'
192.168.1.10 - - [15/Jan/2024:10:00:01] "GET /index.html HTTP/1.1" 200 1024
192.168.1.20 - - [15/Jan/2024:10:00:02] "POST /api/login HTTP/1.1" 200 512
192.168.1.10 - - [15/Jan/2024:10:00:03] "GET /dashboard HTTP/1.1" 200 2048
192.168.1.30 - - [15/Jan/2024:10:00:04] "GET /index.html HTTP/1.1" 404 256
192.168.1.10 - - [15/Jan/2024:10:00:05] "GET /api/users HTTP/1.1" 500 128
192.168.1.20 - - [15/Jan/2024:10:00:06] "GET /index.html HTTP/1.1" 200 1024
192.168.1.40 - - [15/Jan/2024:10:00:07] "GET /admin HTTP/1.1" 403 512
EOF

echo "=== Pipeline: erros 4xx/5xx -> extrai IP e URL -> conta por IP ==="
grep -E ' (4[0-9]{2}|5[0-9]{2}) ' /tmp/acesso.log \
  | sed -E 's/^([^ ]+) .* "(GET|POST|PUT|DELETE) ([^ ]+).*/\1 \3/' \
  | awk '{err[$1" "$2]++} END {for (k in err) print k, err[k]}'

echo
echo "=== Pipeline: top 3 IPs por total de bytes ==="
awk '{bytes[$1] += $10} END {for (ip in bytes) print ip, bytes[ip]}' /tmp/acesso.log \
  | sort -k2 -nr \
  | head -3

echo
echo "=== Pipeline: códigos de resposta únicos ordenados ==="
awk '{print $9}' /tmp/acesso.log | sort -nu

rm /tmp/acesso.log