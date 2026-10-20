#!/usr/bin/env bash
#
# expansao-param.sh - extrai partes de um caminho usando expansão de parâmetros.
#
# Uso: ./expansao-param.sh CAMINHO

[[ $# -eq 1 ]] || { echo "Uso: $0 CAMINHO" >&2; exit 2; }

caminho="$1"

# Diretório pai (remove tudo após o último /)
dir_pai="${caminho%/*}"
# Se não tiver /, dir_pai fica igual a caminho; corrige para "."
[[ "$dir_pai" == "$caminho" ]] && dir_pai="."

# Nome do arquivo com extensão (remove tudo antes do último /)
nome_com_ext="${caminho##*/}"

# Extensão (remove tudo antes do último .)
extensao="${nome_com_ext##*.}"
# Se não tiver ., extensao fica igual ao nome; corrige
[[ "$extensao" == "$nome_com_ext" ]] && extensao=""

# Nome sem extensão
if [[ -n "$extensao" ]]; then
    nome_sem_ext="${nome_com_ext%.*}"
else
    nome_sem_ext="$nome_com_ext"
fi

echo "Caminho original: $caminho"
echo "Diretório pai:    $dir_pai"
echo "Nome c/ ext:      $nome_com_ext"
echo "Nome s/ ext:      $nome_sem_ext"
echo "Extensão:         ${extensao:-(nenhuma)}"