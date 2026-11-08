#!/usr/bin/env bash
#
# valida-backup.sh - validação completa de pré-condições para backup.
#
# Uso: ./valida-backup.sh ORIGEM DESTINO

[[ $# -eq 2 ]] || { echo "Uso: $0 ORIGEM DESTINO" >&2; exit 2; }

origem="$1"
destino="$2"

# 1. Exige root
if [[ $EUID -ne 0 ]]; then
    echo "ERRO: Operação requer root (use sudo)." >&2
    exit 1
fi

# 2. Valida origem
[[ -e "$origem" ]]     || { echo "ERRO: Origem '$origem' não existe" >&2; exit 3; }
[[ -r "$origem" ]]     || { echo "ERRO: Origem '$origem' sem permissão de leitura" >&2; exit 3; }

# 3. Valida destino
[[ -d "$destino" ]]    || { echo "ERRO: Destino '$destino' não é diretório" >&2; exit 3; }
[[ -w "$destino" ]]    || { echo "ERRO: Destino '$destino' sem permissão de escrita" >&2; exit 3; }

# 4. Calcula espaço necessário (tamanho da origem em KB)
tamanho_origem_kb=$(du -sk "$origem" 2>/dev/null | awk '{print $1}')
# Espaço livre no destino em KB
livre_destino_kb=$(df -k "$destino" | awk 'NR==2 {print $4}')

# Requer pelo menos 2x o tamanho (folga para compressão, metadados, etc)
minimo_kb=$(( tamanho_origem_kb * 2 ))

if (( livre_destino_kb < minimo_kb )); then
    echo "ERRO: Espaço insuficiente em $destino" >&2
    echo "  Necessário: ~$(( minimo_kb / 1024 )) MB" >&2
    echo "  Disponível: ~$(( livre_destino_kb / 1024 )) MB" >&2
    exit 4
fi

echo "PRONTO PARA BACKUP"
echo "  Origem: $origem (~$(( tamanho_origem_kb / 1024 )) MB)"
echo "  Destino: $destino (~$(( livre_destino_kb / 1024 )) MB livre)"
exit 0