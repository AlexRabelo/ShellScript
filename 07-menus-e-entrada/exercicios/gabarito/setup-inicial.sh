#!/usr/bin/env bash
#
# setup-inicial.sh - menu de configuração pós-instalação de servidor.
#
# Uso: sudo ./setup-inicial.sh

set -Eeuo pipefail

readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/log.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../06-funcoes/exemplos/lib/valida.sh"

INTERATIVO=0
[[ -t 0 ]] && INTERATIVO=1
DRY_RUN=1  # Padrão seguro

mostra_menu() {
    clear
    echo -e "${AZUL}=== SETUP INICIAL DE SERVIDOR ===${RESET}"
    echo "Modo: $(( DRY_RUN )) && echo DRY-RUN || echo EXECUÇÃO"
    echo
    echo "1) Atualizar pacotes"
    echo "2) Configurar hostname"
    echo "3) Criar usuário admin + sudo"
    echo "4) Configurar SSH (porta, root, chaves)"
    echo "5) Configurar firewall"
    echo "6) Instalar ferramentas base"
    echo "7) Configurar timezone"
    echo "8) Alternar DRY-RUN / EXECUÇÃO"
    echo "9) Sair"
    echo
}

executa() {
    if (( DRY_RUN )); then
        log_aviso "[DRY-RUN] $*"
    else
        log_info "EXEC: $*"
        "$@"
    fi
}

op_atualiza() {
    log_info "Atualizando pacotes..."
    if comando_existe apt-get; then
        executa apt-get update && executa apt-get upgrade -y
    elif comando_existe dnf; then
        executa dnf upgrade -y
    elif comando_existe yum; then
        executa yum update -y
    elif comando_existe apk; then
        executa apk upgrade
    else
        log_erro "Gerenciador não suportado"
    fi
}

op_hostname() {
    read -rp "Novo hostname: " novo
    [[ -z "$novo" ]] && { log_aviso "Vazio"; return; }
    executa hostnamectl set-hostname "$novo"
}

op_usuario_admin() {
    read -rp "Nome do usuário admin: " user
    [[ -z "$user" ]] && { log_aviso "Vazio"; return; }
    if id "$user" >/dev/null 2>&1; then
        log_aviso "Usuário já existe"
    else
        executa useradd -m -s /bin/bash -G sudo,wheel "$user"
        log_info "Defina senha para $user:"
        executa passwd "$user"
    fi
}

op_ssh() {
    log_aviso "Configuração SSH requer edição manual de /etc/ssh/sshd_config"
    log_info "Recomendações:"
    echo "  Port 2222"
    echo "  PermitRootLogin no"
    echo "  PasswordAuthentication no"
    echo "  PubkeyAuthentication yes"
    read -rp "Aplicar recomendações? [s/N] " r
    [[ "${r,,}" == "s" ]] && {
        executa sed -i 's/^#*Port.*/Port 2222/' /etc/ssh/sshd_config
        executa sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        executa sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        executa systemctl reload sshd
    }
}

op_firewall() {
    if comando_existe ufw; then
        executa ufw default deny incoming
        executa ufw default allow outgoing
        executa ufw allow 2222/tcp
        executa ufw --force enable
    elif comando_existe firewall-cmd; then
        executa firewall-cmd --permanent --add-port=2222/tcp
        executa firewall-cmd --reload
    else
        log_aviso "Nenhum firewall suportado encontrado"
    fi
}

op_ferramentas() {
    local pkgs="vim htop curl jq git net-tools iproute2"
    if comando_existe apt-get; then
        executa apt-get install -y $pkgs
    elif comando_existe dnf; then
        executa dnf install -y $pkgs
    elif comando_existe yum; then
        executa yum install -y $pkgs
    elif comando_existe apk; then
        executa apk add $pkgs
    fi
}

op_timezone() {
    read -rp "Timezone (ex: America/Sao_Paulo): " tz
    [[ -z "$tz" ]] && return
    if [[ -f "/usr/share/zoneinfo/$tz" ]]; then
        executa timedatectl set-timezone "$tz"
    else
        log_erro "Timezone inválido"
    fi
}

# Cores
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    VERDE='\033[1;32m'; AMARELO='\033[1;33m'; VERMELHO='\033[1;31m'; AZUL='\033[1;34m'; RESET='\033[0m'
else
    VERDE=''; AMARELO=''; VERMELHO=''; AZUL=''; RESET=''
fi

# Requer root
tem_root || die "Requer root" 1

while true; do
    mostra_menu
    if (( INTERATIVO )); then
        read -rp "Escolha [1-9]: " op
    else
        log_aviso "Não-interativo. Saindo."; exit 0
    fi

    case "$op" in
        1) op_atualiza ;;
        2) op_hostname ;;
        3) op_usuario_admin ;;
        4) op_ssh ;;
        5) op_firewall ;;
        6) op_ferramentas ;;
        7) op_timezone ;;
        8) DRY_RUN=$(( 1 - DRY_RUN )); log_info "Modo: $(( DRY_RUN )) && echo DRY-RUN || echo EXECUÇÃO" ;;
        9) log_info "Saindo..."; exit 0 ;;
        *) log_erro "Inválida" ;;
    esac

    echo
    read -rp "Enter para continuar..." _
done