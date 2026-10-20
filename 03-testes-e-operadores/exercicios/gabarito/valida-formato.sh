#!/usr/bin/env bash
#
# valida-formato.sh - valida formatos comuns com regex.
#
# Uso: ./valida-formato.sh TIPO VALOR
# Tipos: email, ip, data, porta

[[ $# -eq 2 ]] || { echo "Uso: $0 TIPO VALOR" >&2; echo "Tipos: email, ip, data, porta" >&2; exit 2; }

tipo="$1"
valor="$2"

case "$tipo" in
    email)
        # Regex simples de email
        if [[ "$valor" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "Válido: $valor"
            exit 0
        else
            echo "Inválido: '$valor' não é um email válido"
            exit 1
        fi
        ;;
    ip)
        # IPv4 simples (não valida range 0-255 por octeto)
        if [[ "$valor" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Validação extra dos octetos
            IFS='.' read -r o1 o2 o3 o4 <<< "$valor"
            if (( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 )); then
                echo "Válido: $valor"
                exit 0
            fi
        fi
        echo "Inválido: '$valor' não é um IPv4 válido"
        exit 1
        ;;
    data)
        # YYYY-MM-DD
        if [[ "$valor" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            # Validação básica de mês/dia
            IFS='-' read -r ano mes dia <<< "$valor"
            if (( mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31 )); then
                echo "Válido: $valor"
                exit 0
            fi
        fi
        echo "Inválido: '$valor' não é uma data YYYY-MM-DD válida"
        exit 1
        ;;
    porta)
        # 1-65535
        if [[ "$valor" =~ ^[0-9]+$ ]] && (( valor >= 1 && valor <= 65535 )); then
            echo "Válido: $valor"
            exit 0
        else
            echo "Inválido: '$valor' não é uma porta válida (1-65535)"
            exit 1
        fi
        ;;
    *)
        echo "Tipo desconhecido: $tipo" >&2
        echo "Tipos válidos: email, ip, data, porta" >&2
        exit 2
        ;;
esac