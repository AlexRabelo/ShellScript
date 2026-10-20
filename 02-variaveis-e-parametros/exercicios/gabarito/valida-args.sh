#!/usr/bin/env bash
# valida-args.sh — Gabarito Exercício 5

[[ $# -eq 3 ]] || { echo "Uso: $0 ARQUIVO DIRETORIO EXTENSAO" >&2; exit 2; }

arquivo="$1"
dir="$2"
ext="$3"

[[ -f "$arquivo" ]] || { echo "Arquivo não existe: $arquivo" >&2; exit 1; }
[[ -d "$dir" ]] || { echo "Diretório não existe: $dir" >&2; exit 1; }

echo "OK: arquivo=$arquivo, dir=$dir, ext=$ext"