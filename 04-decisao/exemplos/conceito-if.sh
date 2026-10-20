#!/usr/bin/env bash
# conceito-if.sh — if/elif/else (versão didática)

arquivo="/etc/passwd"

echo "=== if simples ==="
if [[ -f "$arquivo" ]]; then
    echo "$arquivo é arquivo regular"
fi

echo
echo "=== if / else ==="
if [[ -d "$arquivo" ]]; then
    echo "É diretório"
else
    echo "NÃO é diretório"
fi

echo
echo "=== if / elif / else ==="
tipo="desconhecido"
if [[ -f "$arquivo" ]]; then
    tipo="arquivo"
elif [[ -d "$arquivo" ]]; then
    tipo="diretório"
elif [[ -L "$arquivo" ]]; then
    tipo="link simbólico"
else
    tipo="outro"
fi
echo "$arquivo é: $tipo"

echo
echo "=== Comando direto no if (grep) ==="
if grep -q "root" "$arquivo"; then
    echo "Usuário 'root' existe no $arquivo"
fi

echo
echo "=== Variável no if (código de saída) ==="
grep -q "nobody" "$arquivo"
if [[ $? -eq 0 ]]; then
    echo "Usuário 'nobody' existe (via \$?)"
fi