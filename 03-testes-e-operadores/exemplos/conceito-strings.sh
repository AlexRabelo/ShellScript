#!/usr/bin/env bash
# conceito-strings.sh — Testes de string (versão didática)

vazio=""
cheio="servidor-web"
menor="a"
maior="z"

echo "=== Vazia / Não vazia ==="
[[ -z "$vazio" ]] && echo "vazio: VAZIA (-z)" || echo "vazio: não vazia"
[[ -n "$cheio" ]] && echo "cheio: NÃO vazia (-n)" || echo "cheio: vazia"

echo
echo "=== Igualdade / Diferença ==="
[[ "$cheio" = "servidor-web" ]] && echo "igual com ="
[[ "$cheio" == "servidor-web" ]] && echo "igual com =="
[[ "$cheio" != "outro" ]] && echo "diferente com !="

echo
echo "=== Glob pattern (só em [[ ]]) ==="
[[ "$cheio" == *web* ]] && echo "contém 'web' (glob)"
[[ "$cheio" == servidor-* ]] && echo "começa com 'servidor-'"

echo
echo "=== Regex com =~ (só em [[ ]]) ==="
[[ "$cheio" =~ ^servidor- ]] && echo "regex: começa com 'servidor-'"
[[ "$cheio" =~ [0-9]+$ ]] && echo "regex: termina com dígito"
[[ "$cheio" =~ web ]] && echo "regex: contém 'web'"

echo
echo "=== Comparação lexicográfica (ordem alfabética) ==="
[[ "$menor" < "$maior" ]] && echo "a < b"
[[ "$maior" > "$menor" ]] && echo "z > a"