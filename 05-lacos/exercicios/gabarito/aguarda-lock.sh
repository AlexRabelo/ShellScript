#!/usr/bin/env bash
#
# aguarda-lock.sh - demonstra uso de flock com until para aguardar lock.
#
# Uso: ./aguarda-lock.sh CAMINHO_LOCKFILE

[[ $# -eq 1 ]] || { echo "Uso: $0 CAMINHO_LOCKFILE" >&2; exit 2; }

lockfile="$1"

# Abre FD 9 para o lockfile
exec 9>"$lockfile"

echo "Tentando obter lock em $lockfile ..."

# until tenta adquirir lock exclusivo não-bloqueante
until flock -n 9; do
    echo "  Lock ocupado. Aguardando 2s..."
    sleep 2
done

echo "Lock obtido! Simulando trabalho por 5s..."
sleep 5

echo "Trabalho concluído. Liberando lock automaticamente (trap EXIT)."

# O lock é liberado automaticamente quando o script sai (FD 9 fecha)
# Mas podemos ser explícitos:
# flock -u 9

exit 0