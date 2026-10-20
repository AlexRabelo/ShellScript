#!/usr/bin/env bash
# conceito-ifs-mapfile.sh — IFS, read -a, mapfile (versão didática)

echo "=== IFS customizado + read -a ==="
linha="usuario:1001:/home/usuario:/bin/bash"
IFS=: read -r -a campos <<< "$linha"
echo "campos: ${campos[*]}"
echo "quantidade: ${#campos[@]}"
for i in "${!campos[@]}"; do
    echo "  [$i] = ${campos[i]}"
done

echo
echo "=== mapfile -t (lê arquivo em array) ==="
cat > /tmp/teste.txt << 'EOF'
linha 1
linha 2
linha 3
EOF

mapfile -t linhas < /tmp/teste.txt
echo "linhas: ${linhas[*]}"
for i in "${!linhas[@]}"; do
    echo "  [$i] = ${linhas[i]}"
done

echo
echo "=== mapfile com callback (bash 4.4+) ==="
mapfile -t -C 'echo "Lida: %s"' -c 1 < /tmp/teste.txt

rm /tmp/teste.txt