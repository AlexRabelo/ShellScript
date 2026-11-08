#!/usr/bin/env bash
#
# menu-select-sub.sh - menu principal com submenus usando select.
#
# Uso: ./menu-select-sub.sh

PS3=$'\n'"Escolha uma opção: "

menu_principal() {
    echo "=== MENU PRINCIPAL ==="
    select opcao in "Gerenciar Serviços" "Ver Logs" "Configuração" "Sair"; do
        case "$REPLY" in
            1) menu_servicos ;;
            2) menu_logs ;;
            3) menu_config ;;
            4) echo "Saindo..."; exit 0 ;;
            *) echo "Opção inválida" ;;
        esac
    done
}

menu_servicos() {
    echo
    echo "--- GERENCIAR SERVIÇOS ---"
    select opcao in "Listar Ativos" "Iniciar" "Parar" "Reiniciar" "Voltar"; do
        case "$REPLY" in
            1) systemctl list-units --type=service --state=active --no-pager ;;
            2) read -rp "Serviço: " s; systemctl start "$s" ;;
            3) read -rp "Serviço: " s; systemctl stop "$s" ;;
            4) read -rp "Serviço: " s; systemctl restart "$s" ;;
            5) break ;;  # Volta ao menu principal
            *) echo "Opção inválida" ;;
        esac
    done
}

menu_logs() {
    echo
    echo "--- VER LOGS ---"
    select opcao in "Sistema (journalctl)" "Autenticação" "Kernel" "Voltar"; do
        case "$REPLY" in
            1) journalctl -n 50 --no-pager ;;
            2) journalctl -u ssh -n 30 --no-pager ;;
            3) dmesg -T | tail -30 ;;
            4) break ;;
            *) echo "Opção inválida" ;;
        esac
    done
}

menu_config() {
    echo
    echo "--- CONFIGURAÇÃO ---"
    echo "1) Hostname: $(hostname)"
    echo "2) IP: $(hostname -I)"
    echo "3) Kernel: $(uname -r)"
    echo "4) Voltar"
    read -rp "Escolha: " o
    [[ "$o" == "4" ]] && return
}

menu_principal