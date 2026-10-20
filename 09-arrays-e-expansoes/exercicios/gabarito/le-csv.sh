#!/usr/bin/env bash
# le-csv.sh — Gabarito Exercício 4

cat > /tmp/dados.csv << 'EOF'
nome,idade,cidade
João,30,São Paulo
Maria,25,Rio de Janeiro
Pedro,35,Belo Horizonte
EOF

# Pula cabeçalho
tail -n +2 /tmp/dados.csv | while IFS=, read -r nome idade cidade; do
    echo "Nome: $nome, Idade: $idade, Cidade: $cidade"
done

rm /tmp/dados.csv