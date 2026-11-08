#!/usr/bin/env bash
#
# ips-ssh.sh - IPs com falhas de autenticação SSH.
#
# Uso: ./ips-ssh.sh [ARQUIVO_LOG] [TOP_N]

set -Eeuo pipefail

ARQUIVO="${1:-/var/log/auth.log}"
TOP_N="${2:-20}"

# Se não existir auth.log, tenta journalctl
if [[ ! -f "$ARQUIVO" ]]; then
    echo "Arquivo não encontrado, usando journalctl..." >&2
    ARQUIVO="/tmp/ssh-auth.log"
    journalctl -u sshd --no-pager -n 1000 > "$ARQUIVO" 2>/dev/null || {
        echo "ERRO: Não foi possível obter logs SSH" >&2
        exit 1
    }
fi

echo "=== Top $TOP_N IPs com Falhas SSH ==="
echo "Fonte: $ARQUIVO"
echo

# Regex para "Failed password for ... from IP"
grep -E "Failed password|Invalid user.*from" "$ARQUIVO" | \
    grep -oE 'from [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
    sed 's/from //' | \
    LC_ALL=C sort | uniq -c | LC_ALL=C sort -rn | \
    head -"$TOP_N" | \
    awk '{printf "%4d  %s\n", $1, $2}'

echo
echo "=== Por usuário alvo ==="
grep -E "Failed password" "$ARQUIVO" | \
    sed -E 's/.*Failed password for ([^ ]+) from.*/\1/' | \
    LC_ALL=C sort | uniq -c | LC_ALL=C sort -rn | head -10