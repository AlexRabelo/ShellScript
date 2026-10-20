#!/usr/bin/env bash
#
# lib/valida.sh - Biblioteca de validações comuns

requer_comando() {
    command -v "$1" >/dev/null 2>&1 || { log_erro "Comando obrigatório não encontrado: $1"; return 3; }
}

valida_arquivo() {
    [[ -f "$1" ]] || { log_erro "Arquivo não encontrado: $1"; return 1; }
    [[ -r "$1" ]] || { log_erro "Sem permissão de leitura: $1"; return 1; }
}

valida_diretorio() {
    [[ -d "$1" ]] || { log_erro "Diretório não existe: $1"; return 1; }
    [[ -r "$1" ]] || { log_erro "Sem permissão de leitura: $1"; return 1; }
    [[ -w "$1" ]] || { log_erro "Sem permissão de escrita: $1"; return 1; }
}

valida_numero() {
    local valor="$1" nome="${2:-valor}"
    [[ "$valor" =~ ^[0-9]+$ ]] || { log_erro "$nome deve ser número inteiro positivo: $valor"; return 2; }
    (( valor > 0 )) || { log_erro "$nome deve ser maior que zero: $valor"; return 2; }
}

valida_ip() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    IFS='.' read -r a b c d <<< "$ip"
    (( a <= 255 && b <= 255 && c <= 255 && d <= 255 ))
}

valida_url() {
    [[ "$1" =~ ^https?:// ]] || return 1
}

valida_porta() {
    local porta="$1"
    [[ "$porta" =~ ^[0-9]+$ ]] && (( porta >= 1 && porta <= 65535 ))
}