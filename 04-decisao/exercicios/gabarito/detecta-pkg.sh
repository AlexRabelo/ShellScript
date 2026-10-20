#!/usr/bin/env bash
#
# detecta-pkg.sh - identifica o gerenciador de pacotes da distribuição.
#
# Uso: ./detecta-pkg.sh

if [[ ! -f /etc/os-release ]]; then
    echo "DESCONHECIDO: /etc/os-release não encontrado" >&2
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

case "$ID" in
    ubuntu|debian|linuxmint|pop|elementary|zorin)
        echo "apt"
        ;;
    rhel|centos|rocky|almalinux|fedora|oracle|amzn)
        echo "dnf"
        ;;
    alpine)
        echo "apk"
        ;;
    arch|manjaro|endeavouros)
        echo "pacman"
        ;;
    opensuse*|sles)
        echo "zypper"
        ;;
    *)
        echo "DESCONHECIDO: $ID" >&2
        exit 1
        ;;
esac