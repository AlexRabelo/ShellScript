#!/usr/bin/env bash
# conceito-select.sh — Menu interativo com select (versão didática)

PS3="Escolha uma opção: "
opcoes=("Ver data" "Ver usuários logados" "Ver uso de disco" "Sair")

echo "=== Menu select ==="
select escolha in "${opcoes[@]}"; do
    case "$escolha" in
        "Ver data")
            date
            ;;
        "Ver usuários logados")
            who
            ;;
        "Ver uso de disco")
            df -h /
            ;;
        "Sair")
            echo "Encerrando..."
            break
            ;;
        *)
            echo "Opção inválida: $REPLY"
            ;;
    esac
done