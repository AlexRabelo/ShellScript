#!/usr/bin/env bash
#
# valida-entrada.sh - funções de leitura e validação robustas.
#
# Uso: ./valida-entrada.sh

set -Eeuo pipefail

# Função: Lê inteiro com validação de faixa
le_inteiro() {
    local prompt="$1"
    local min="${2:-}"
    local max="${3:-}"
    local valor

    while true; do
        read -rp "$prompt " valor
        if [[ "$valor" =~ ^-?[0-9]+$ ]]; then
            if [[ -n "$min" ]] && (( valor < min )); then
                echo "Valor deve ser >= $min" >&2
                continue
            fi
            if [[ -n "$max" ]] && (( valor > max )); then
                echo "Valor deve ser <= $max" >&2
                continue
            fi
            echo "$valor"
            return 0
        fi
        echo "Digite um número inteiro válido" >&2
    done
}

# Função: Lê e valida IPv4
le_ip() {
    local prompt="$1"
    local ip

    while true; do
        read -rp "$prompt " ip
        if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
            if (( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 )); then
                echo "$ip"
                return 0
            fi
        fi
        echo "IPv4 inválido. Formato: X.X.X.X (0-255 cada)" >&2
    done
}

# Função: Lê e valida email (simples)
le_email() {
    local prompt="$1"
    local email

    while true; do
        read -rp "$prompt " email
        if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "$email"
            return 0
        fi
        echo "Email inválido. Ex: usuario@dominio.com" >&2
    done
}

# Função: Lê opção de uma lista
le_opcao() {
    local prompt="$1"
    shift
    local opcoes=("$@")
    local escolha

    while true; do
        read -rp "$prompt " escolha
        for opcao in "${opcoes[@]}"; do
            if [[ "$escolha" == "$opcao" ]]; then
                echo "$escolha"
                return 0
            fi
        done
        echo "Opção inválida. Válidas: ${opcoes[*]}" >&2
    done
}

# Demonstração
echo "=== Demonstração de Validação de Entrada ==="
echo

idade=$(le_inteiro "Idade (18-100):" 18 100)
echo "Idade registrada: $idade"

ip=$(le_ip "IP do servidor:")
echo "IP registrado: $ip"

email=$(le_email "Email para alertas:")
echo "Email registrado: $email"

ambiente=$(le_opcao "Ambiente (producao/homologacao/desenvolvimento):" producao homologacao desenvolvimento)
echo "Ambiente: $ambiente"

echo
echo "Todos os valores validados com sucesso!"