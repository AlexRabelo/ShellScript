#!/usr/bin/env bash
# conceito-grep.sh — grep variantes (versão didática)

cat > /tmp/teste.log << 'EOF'
2024-01-15 10:00:01 INFO  Iniciando servidor
2024-01-15 10:00:02 ERRO  Falha na conexão
2024-01-15 10:00:03 WARN  Timeout na requisição
2024-01-15 10:00:04 INFO  Tentando novamente
2024-01-15 10:00:05 ERRO  Falha crítica
2024-01-15 10:00:06 INFO  Servidor parado
EOF

echo "=== Básico ==="
grep "ERRO" /tmp/teste.log

echo
echo "=== -i case-insensitive ==="
grep -i "erro" /tmp/teste.log

echo
echo "=== -v invertido ==="
grep -v "INFO" /tmp/teste.log

echo
echo "=== -c conta ==="
grep -c "ERRO" /tmp/teste.log

echo
echo "=== -n número da linha ==="
grep -n "ERRO" /tmp/teste.log

echo
echo "=== -E regex estendida (OU) ==="
grep -E "ERRO|WARN" /tmp/teste.log

echo
echo "=== -A/-B/-C contexto ==="
grep -A 1 -B 1 "ERRO" /tmp/teste.log

echo
echo "=== -r recursivo (diretório) ==="
grep -r "ERRO" /tmp/ 2>/dev/null | head -5

rm /tmp/teste.log