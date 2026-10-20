#!/usr/bin/env bash
# conceito-sed.sh — sed transformações (versão didática)

cat > /tmp/teste.txt << 'EOF'
usuario:joao:1001:/home/joao:/bin/bash
usuario:maria:1002:/home/maria:/bin/zsh
usuario:pedro:1003:/home/pedro:/bin/bash
EOF

echo "=== s/// substituição simples ==="
sed 's/usuario/USER/' /tmp/teste.txt

echo
echo "=== s///g global (todas na linha) ==="
sed 's/:/ | /g' /tmp/teste.txt

echo
echo "=== s///gi case-insensitive ==="
sed 's/BASH/zsh/gi' /tmp/teste.txt

echo
echo "=== Delimitador alternativo (útil para paths) ==="
sed 's|/home|/users|g' /tmp/teste.txt

echo
echo "=== d — deleta linhas ==="
sed '2d' /tmp/teste.txt                    # apaga linha 2
sed '1,2d' /tmp/teste.txt                  # apaga linhas 1-2
sed '/maria/d' /tmp/teste.txt              # apaga linha com 'maria'

echo
echo "=== -n p — imprime só linhas específicas ==="
sed -n '1p' /tmp/teste.txt                 # só linha 1
sed -n '1,2p' /tmp/teste.txt               # linhas 1-2
sed -n '/joao/p' /tmp/teste.txt            # linhas com 'joao'

echo
echo "=== y/// — transliteração ==="
echo "abc" | sed 'y/abc/XYZ/'

rm /tmp/teste.txt