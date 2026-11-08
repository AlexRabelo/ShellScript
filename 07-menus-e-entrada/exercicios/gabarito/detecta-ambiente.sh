#!/usr/bin/env bash
#
# detecta-ambiente.sh - detecta características do ambiente de execução.
#
# Uso: ./detecta-ambiente.sh

echo "=== Detecção de Ambiente ==="
echo

# Terminal interativo
if [[ -t 0 ]]; then
    echo "✓ Terminal interativo: SIM (stdin é TTY)"
else
    echo "✗ Terminal interativo: NÃO (stdin é pipe/arquivo)"
fi

# Root
if [[ $EUID -eq 0 ]]; then
    echo "✓ Root: SIM (EUID=0)"
else
    echo "✗ Root: NÃO (EUID=$EUID)"
fi

# Container
if [[ -f /.dockerenv ]]; then
    echo "✓ Container: SIM (/.dockerenv existe)"
elif grep -q 'docker\|containerd\|lxc' /proc/1/cgroup 2>/dev/null; then
    echo "✓ Container: SIM (cgroup indica container)"
else
    echo "✗ Container: NÃO detectado"
fi

# CI/CD
ci_detectado=0
for var in CI GITHUB_ACTIONS GITLAB_CI BITBUCKET_BUILD_NUMBER BUILDKITE CIRCLECI TRAVIS DRONE; do
    if [[ -n "${!var:-}" ]]; then
        echo "✓ CI/CD: SIM ($var=${!var})"
        ci_detectado=1
    fi
done
(( ci_detectado == 0 )) && echo "✗ CI/CD: NÃO detectado"

# Display gráfico
if [[ -n "${DISPLAY:-}" ]]; then
    echo "✓ Display X11: SIM (DISPLAY=$DISPLAY)"
elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo "✓ Display Wayland: SIM (WAYLAND_DISPLAY=$WAYLAND_DISPLAY)"
else
    echo "✗ Display gráfico: NÃO"
fi

# Suporte a cores
if command -v tput >/dev/null 2>&1; then
    cores=$(tput colors 2>/dev/null || echo 0)
    if (( cores >= 8 )); then
        echo "✓ Cores: SIM (tput colors=$cores)"
    else
        echo "✗ Cores: NÃO (tput colors=$cores)"
    fi
else
    echo "? Cores: tput não disponível"
fi

# Variáveis de ambiente úteis
echo
echo "--- Variáveis de Ambiente ---"
for var in HOSTNAME USER HOME SHELL TERM LANG PATH; do
    echo "  $var=${!var:-<não definido>}"
done