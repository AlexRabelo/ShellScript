#!/usr/bin/env bash
# conceito-arrays.sh — Arrays indexados e associativos (versão didática)

echo "=== Array indexado ==="
servidores=("web01" "web02" "db01")
servidores[3]="cache01"
servidores+=("backup01")

echo "Elemento 0: ${servidores[0]}"
echo "Todos: ${servidores[*]}"
echo "Quantidade: ${#servidores[@]}"
echo "Índices: ${!servidores[*]}"

echo
echo "Iteração correta:"
for s in "${servidores[@]}"; do
    echo "  -> $s"
done

echo
echo "=== Array associativo (declare -A) ==="
declare -A ports=( ["http"]=80 ["https"]=443 ["ssh"]=22 )
ports["dns"]=53

echo "ports[https]=${ports[https]}"
echo "Chaves: ${!ports[*]}"
echo "Valores: ${ports[*]}"
echo "Quantidade: ${#ports[@]}"

echo
echo "Iteração por chave:"
for svc in "${!ports[@]}"; do
    echo "  $svc -> ${ports[$svc]}"
done