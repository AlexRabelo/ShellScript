#!/usr/bin/env bash
#
# lib/valida.sh - funções reutilizáveis de validação para infra/SRE.
#
# Uso:
#   source "${SCRIPT_DIR}/lib/valida.sh"
#   eh_ip "$IP" && echo "Válido"
#   eh_porta 8080 || die "Porta inválida"
#   comando_existe curl || die "curl não instalado"
#   tem_root || die "Requer root"

# Verifica se string é um IPv4 válido
eh_ip() {
    local ip="${1:-}"
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || return 1
    IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
    (( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 ))
}

# Verifica se string é uma porta válida (1-65535)
eh_porta() {
    local porta="${1:-}"
    [[ "$porta" =~ ^[0-9]+$ ]] || return 1
    (( porta >= 1 && porta <= 65535 ))
}

# Verifica se comando existe no PATH
comando_existe() {
    command -v "$1" > /dev/null 2>&1
}

# Verifica se está rodando como root
tem_root() {
    [[ $EUID -eq 0 ]]
}

# Verifica se arquivo existe e é legível
arquivo_legivel() {
    local arq="${1:-}"
    [[ -f "$arq" && -r "$arq" ]]
}

# Verifica se diretório existe e é gravável
dir_gravavel() {
    local dir="${1:-}"
    [[ -d "$dir" && -w "$dir" ]]
}

# Verifica se serviço systemd está ativo
servico_ativo() {
    local servico="${1:-}"
    systemctl is-active "$servico" > /dev/null 2>&1
}

# Verifica se porta TCP está aberta (timeout 2s)
porta_aberta() {
    local host="${1:-}"
    local porta="${2:-}"
    timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$porta" 2>/dev/null
}

# Retorna timestamp ISO 8601
timestamp_iso() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# Retorna hostname curto
hostname_curto() {
    hostname -s
}