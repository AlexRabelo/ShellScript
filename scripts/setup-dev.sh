#!/usr/bin/env bash
# =============================================================================
# setup-dev.sh — Configura ambiente de desenvolvimento local
# =============================================================================
# Uso: ./scripts/setup-dev.sh
# Instala: shellcheck, bats, jq, curl, pre-commit, commitizen
# =============================================================================

set -Eeuo pipefail

echo "🔧 Configurando ambiente de desenvolvimento para Shell Script Course"
echo ""

# Detecta OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

install_apt() {
    echo "📦 Atualizando apt e instalando dependências..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        shellcheck \
        bats \
        jq \
        curl \
        git \
        python3-pip
}

install_brew() {
    echo "📦 Instalando via Homebrew..."
    brew install shellcheck bats-core jq curl git python
}

install_pip_packages() {
    echo "🐍 Instalando pacotes Python (pre-commit, commitizen)..."
    pip3 install --user --quiet \
        pre-commit \
        commitizen
    # Adiciona ~/.local/bin ao PATH se necessário
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

setup_pre_commit() {
    echo "🪝 Configurando pre-commit hooks..."
    pre-commit install
    pre-commit install --hook-type commit-msg
    echo "✅ Pre-commit configurado (roda em commit e commit-msg)"
}

setup_git_config() {
    echo "⚙️  Configurando Git (se não configurado)..."
    if ! git config user.name >/dev/null 2>&1; then
        read -rp "Git user.name: " git_name
        git config --global user.name "$git_name"
    fi
    if ! git config user.email >/dev/null 2>&1; then
        read -rp "Git user.email: " git_email
        git config --global user.email "$git_email"
    fi
    # Configurações recomendadas
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    echo "✅ Git configurado"
}

verify_tools() {
    echo ""
    echo "🔍 Verificando ferramentas instaladas..."
    local tools=("shellcheck" "bats" "jq" "curl" "git" "pre-commit" "cz")
    local all_ok=1

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            version=$($tool --version 2>&1 | head -1)
            echo -e "  ✅ $tool: $version"
        else
            echo -e "  ❌ $tool: NÃO ENCONTRADO"
            all_ok=0
        fi
    done

    if [[ $all_ok -eq 1 ]]; then
        echo ""
        echo -e "${GREEN}🎉 Ambiente pronto para desenvolvimento!${NC}"
        echo ""
        echo "Próximos passos:"
        echo "  1. git checkout -b release/v0.X-modulo-NN"
        echo "  2. Desenvolver módulo seguindo DoD (VERSIONAMENTO.md)"
        echo "  3. git add . && git commit -m 'feat(modulo-NN): ...'"
        echo "  4. git push && gh pr create"
    else
        echo ""
        echo -e "${RED}⚠️  Algumas ferramentas faltando. Verifique a instalação.${NC}"
        exit 1
    fi
}

# Execução principal
case "$OS" in
    ubuntu|debian|linuxmint|pop|kali)
        install_apt
        ;;
    darwin|macos)
        if command -v brew >/dev/null 2>&1; then
            install_brew
        else
            echo "❌ Homebrew não encontrado. Instale em https://brew.sh"
            exit 1
        fi
        ;;
    *)
        echo "⚠️  OS não reconhecido ($OS). Tentando apt..."
        install_apt
        ;;
esac

install_pip_packages
setup_pre_commit
setup_git_config
verify_tools