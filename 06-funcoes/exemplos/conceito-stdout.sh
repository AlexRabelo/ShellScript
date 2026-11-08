#!/usr/bin/env bash
# conceito-stdout.sh — Retorno via stdout (versão didática)

echo "=== Retorno via stdout — capture com \$() ==="
dobro() {
    local n="$1"
    echo $(( n * 2 ))
}

triplo() {
    local n="$1"
    echo $(( n * 3 ))
}

echo "Dobro de 7: $(dobro 7)"
echo "Triplo de 7: $(triplo 7)"

echo
echo "=== Encadeamento: saída de uma vira entrada da outra ==="
resultado=$(triplo $(dobro 5))
echo "Triplo do dobro de 5: $resultado"

echo
echo "=== Múltiplas linhas no stdout ==="
lista_pares() {
    local max="$1"
    for (( i=2; i<=max; i+=2 )); do
        echo $i
    done
}

echo "Pares até 10:"
mapfile -t pares < <(lista_pares 10)
printf '  %s\n' "${pares[@]}"