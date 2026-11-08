#!/usr/bin/env bash
# conceito-arquivos.sh — Testes de arquivo (versão didática)

arquivo="/etc/passwd"
dir="/etc"
inexistente="/isso/nao/existe"
vazio="/tmp/vazio-$$"
touch "$vazio"

echo "=== Existência e tipo ==="
[[ -e "$arquivo" ]] && echo "$arquivo: existe (-e)"
[[ -f "$arquivo" ]] && echo "$arquivo: arquivo regular (-f)"
[[ -d "$dir" ]] && echo "$dir: diretório (-d)"
[[ -L "$arquivo" ]] || echo "$arquivo: não é link (-L)"
[[ ! -e "$inexistente" ]] && echo "$inexistente: não existe"

echo
echo "=== Permissões ==="
[[ -r "$arquivo" ]] && echo "$arquivo: legível (-r)"
[[ -w "$arquivo" ]] && echo "$arquivo: gravável (-w)"
[[ -x "$arquivo" ]] || echo "$arquivo: não executável (-x)"

echo
echo "=== Tamanho e tempo ==="
[[ -s "$arquivo" ]] && echo "$arquivo: tem conteúdo (-s)"
[[ ! -s "$vazio" ]] && echo "$vazio: vazio (! -s)"
[[ "$arquivo" -nt "$vazio" ]] && echo "$arquivo mais novo que $vazio (-nt)"
[[ "$vazio" -ot "$arquivo" ]] && echo "$vazio mais velho que $arquivo (-ot)"

rm -f "$vazio"