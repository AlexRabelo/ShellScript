#!/usr/bin/env bash
#
# filtra-servidores.sh - demonstra break e continue em laço.
#
# Uso: ./filtra-servidores.sh

# Array de servidores simulados (nome:status)
SERVIDORES=(
    "web01:online"
    "web02:online"
    "db01:manutencao"
    "cache01:online"
    "lb01:offline"
    "app01:offline"
    "app02:offline"
    "mq01:online"
    "mq02:manutencao"
    "monitor:online"
)

# Lista de servidores em manutenção (para pular com continue)
MANUTENCAO=("db01" "mq02")

offline_consecutivos=0

echo "=== Varredura de Servidores ==="
echo

for entrada in "${SERVIDORES[@]}"; do
    IFS=':' read -r nome status <<< "$entrada"

    # Pula servidores em manutenção
    if [[ " ${MANUTENCAO[*]} " == *" $nome "* ]]; then
        echo "  $nome: EM MANUTENÇÃO - pulando (continue)"
        continue
    fi

    echo -n "  $nome: $status"

    if [[ "$status" == "offline" ]]; then
        echo " -> ALERTA OFFLINE"
        (( offline_consecutivos++ ))
        if (( offline_consecutivos >= 3 )); then
            echo ""
            echo "!!! 3 SERVIDORES OFFLINE CONSECUTIVOS - ABORTANDO (break) !!!"
            break
        fi
    else
        echo " -> OK"
        offline_consecutivos=0
    fi
done

echo
echo "Varredura finalizada."