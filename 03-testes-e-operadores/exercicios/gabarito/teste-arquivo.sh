#!/usr/bin/env bash
# teste-arquivo.sh — Gabarito Exercício 3

caminho="${1:-$0}"

echo "Testando: $caminho"
echo

[[ -e "$caminho" ]] && echo "existe (-e): SIM" || echo "existe (-e): NÃO"
[[ -f "$caminho" ]] && echo "é arquivo (-f): SIM" || echo "é arquivo (-f): NÃO"
[[ -d "$caminho" ]] && echo "é diretório (-d): SIM" || echo "é diretório (-d): NÃO"
[[ -r "$caminho" ]] && echo "legível (-r): SIM" || echo "legível (-r): NÃO"
[[ -s "$caminho" ]] && echo "tem conteúdo (-s): SIM" || echo "tem conteúdo (-s): NÃO"