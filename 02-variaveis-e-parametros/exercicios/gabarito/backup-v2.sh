#!/usr/bin/env bash
#
# backup-v2.sh - cria backup com timestamp no nome.
#
# Uso: ./backup-v2.sh ARQUIVO

[[ $# -eq 1 ]] || { echo "Uso: $0 ARQUIVO" >&2; exit 2; }

origem="$1"
destino="/tmp/backups"

[[ -f "$origem" ]] || { echo "Erro: arquivo '$origem' não existe" >&2; exit 1; }

mkdir -p "$destino"

# Extrai nome base e extensão
nome_base="${origem##*/}"
nome_sem_ext="${nome_base%.*}"
extensao="${nome_base##*.}"
[[ "$nome_base" == "$extensao" ]] && extensao="" && nome_sem_ext="$nome_base"

# Timestamp compacto: YYYYMMDD-HHMMSS
timestamp="$(date +%Y%m%d-%H%M%S)"

if [[ -n "$extensao" ]]; then
    backup="${destino}/${nome_sem_ext}-${timestamp}.${extensao}"
else
    backup="${destino}/${nome_sem_ext}-${timestamp}"
fi

cp "$origem" "$backup"

echo "Backup criado: $backup"
echo "Tamanho: $(du -h "$backup" | cut -f1)"