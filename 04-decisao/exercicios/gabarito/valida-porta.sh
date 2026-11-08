#!/usr/bin/env bash
#
# valida-porta.sh - testa conectividade TCP em host:porta.
#
# Uso: ./valida-porta.sh HOST PORTA

[[ $# -eq 2 ]] || { echo "Uso: $0 HOST PORTA" >&2; exit 2; }

host="$1"
porta="$2"

# Valida porta numérica
[[ "$porta" =~ ^[0-9]+$ ]] || { echo "ERRO: Porta deve ser numérica" >&2; exit 2; }
(( porta >= 1 && porta <= 65535 )) || { echo "ERRO: Porta deve ser entre 1-65535" >&2; exit 2; }

# Testa conexão TCP com timeout de 2s
# Método 1: bash built-in /dev/tcp (mais portável)
if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$porta" 2>/dev/null; then
    echo "PORTA ABERTA: $host:$porta"
    exit 0
# Método 2: fallback para nc se disponível
elif command -v nc >/dev/null && nc -z -w 2 "$host" "$porta" 2>/dev/null; then
    echo "PORTA ABERTA: $host:$porta"
    exit 0
else
    echo "PORTA FECHADA: $host:$porta"
    exit 1
fi