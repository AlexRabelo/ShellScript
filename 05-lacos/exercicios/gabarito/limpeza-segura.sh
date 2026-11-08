#!/usr/bin/env bash
#
# limpeza-segura.sh - remove arquivos com padrão e idade com confirmação.
#
# Uso: ./limpeza-segura.sh DIRETORIO PADRAO DIAS [--exec]
#   Ex: ./limpeza-segura.sh /tmp "*.tmp" 7 --exec

[[ $# -ge 3 ]] || { echo "Uso: $0 DIRETORIO PADRAO DIAS [--exec]" >&2; exit 2; }

diretorio="$1"
padrao="$2"
dias="$3"
modo="${4:-dry-run}"

[[ -d "$diretorio" ]] || { echo "ERRO: Diretório '$diretorio' não existe" >&2; exit 1; }
[[ "$dias" =~ ^[0-9]+$ ]] || { echo "ERRO: Dias deve ser inteiro" >&2; exit 2; }

encontrados=()
tamanho_total=0

# find com -print0 para lidar com espaços/nomes especiais
while IFS= read -r -d '' arquivo; do
    [[ -f "$arquivo" ]] || continue
    tam=$(stat -c%s "$arquivo" 2>/dev/null || stat -f%z "$arquivo" 2>/dev/null)
    encontrados+=("$arquivo")
    tamanho_total=$(( tamanho_total + tam ))
done < <(find "$diretorio" -type f -name "$padrao" -mtime "+$dias" -print0 2>/dev/null)

if (( ${#encontrados[@]} == 0 )); then
    echo "Nenhum arquivo encontrado."
    exit 0
fi

echo "=== Limpeza Segura ==="
echo "Diretório: $diretorio"
echo "Padrão:    $padrao"
echo "Idade:     > $dias dias"
echo "Modo:      $modo"
echo
echo "Arquivos (${#encontrados[@]}):"
for arq in "${encontrados[@]}"; do
    tam_h=$(numfmt --to=iec-i --suffix=B "$(stat -c%s "$arq" 2>/dev/null || stat -f%z "$arq" 2>/dev/null)")
    echo "  $arq ($tam_h)"
done
total_h=$(numfmt --to=iec-i --suffix=B "$tamanho_total")
echo "Total a liberar: $total_h"

if [[ "$modo" == "--exec" ]]; then
    echo
    read -rp "Confirmar exclusão permanente? [s/N] " conf
    [[ "${conf,,}" == "s" ]] || { echo "Cancelado."; exit 0; }

    for arq in "${encontrados[@]}"; do
        rm -f "$arq" && echo "Removido: $arq" || echo "Falha: $arq" >&2
    done
    echo "Limpeza concluída."
else
    echo
    echo "DRY-RUN: use --exec para executar."
fi