#!/usr/bin/env bash
# Lab: Módulo 15 — Projeto Integrador (SRE Toolkit)
# Tempo: 60 min | Objetivo: Extensão do SRE Toolkit com subcomando customizado

# =============================================================================
# ENUNCIADO
# =============================================================================
# Sua tarefa como SRE é estender o toolkit corporativo adicionando um novo
# subcomando de monitoramento de certificados SSL/TLS.
#
# O subcomando `ssl` deve:
# 1. Verificar expiração de certificados para uma lista de domínios
# 2. Alertar se expira em menos de X dias (configurável, padrão 30)
# 3. Suportar saída em texto formatado e JSON (`-j`)
# 4. Suportar dry-run (`-n`)
# 5. Integrar com `lib/log.sh`, `lib/util.sh` e `lib/alerta.sh`
# 6. Passar no shellcheck com zero avisos

# =============================================================================
# ARQUITETURA ESPERADA
# =============================================================================
# sre-toolkit/
# ├── bin/
# │   └── sre-toolkit          # Entrypoint com dispatch de subcomandos
# ├── lib/
# │   ├── alerta.sh            # Funções de notificação (stdout/webhook)
# │   ├── log.sh               # Logging com timestamp ISO e níveis
# │   └── util.sh              # run(), json_output(), valida_dep()
# ├── comandos/
# │   ├── saude.sh             # Subcomando existente de healthcheck
# │   ├── backup.sh            # Subcomando existente de backup
# │   └── ssl.sh               # NOVO subcomando que você vai implementar
# └── testes/
#     └── ssl.bats             # Testes unitários do subcomando

# =============================================================================
# TEMPLATE DO SUBCOMANDO: comandos/ssl.sh
# =============================================================================

# Strict mode
set -Eeuo pipefail

# Diretório base
COMANDO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${COMANDO_DIR}/../lib"

# Importa bibliotecas compartilhadas
# shellcheck source=/dev/null
source "${LIB_DIR}/log.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/util.sh"
# shellcheck source=/dev/null
source "${LIB_DIR}/alerta.sh"

# Configurações padrão
DIAS_ALERTA=30
PORTA_PADRAO=443
JSON_OUTPUT=0  # Usado na função saida_json (a implementar)

usage() {
    cat <<EOF
Uso: sre-toolkit ssl [OPÇÕES] DOMÍNIO [DOMÍNIO...]

Verifica expiração de certificados SSL/TLS em domínios remotos.

Opções:
  -d DIAS       Dias para alerta de expiração (padrão: 30)
  -p PORTA      Porta de conexão (padrão: 443)
  -j            Saída em formato JSON
  -n            Dry-run (apenas simula a verificação)
  -h            Exibe esta ajuda

Exemplos:
  sre-toolkit ssl google.com github.com
  sre-toolkit ssl -d 15 -j internal.corp.net
EOF
}

# TODO: Implemente a função de verificação de certificado
# Usa openssl s_client para buscar cert e calcular dias restantes
#
# Dica de comando openssl:
#   openssl s_client -servername "$dominio" -connect "${dominio}:${porta}" </dev/null 2>/dev/null \
#     | openssl x509 -noout -enddate
#
# Para calcular dias restantes:
#   data_exp=$(...)
#   epoch_exp=$(date -d "$data_exp" +%s)
#   epoch_agora=$(date +%s)
#   dias_restantes=$(( (epoch_exp - epoch_agora) / 86400 ))

verifica_ssl() {
    local dominio="$1"
    local porta="$2"

    log_debug "Verificando SSL para ${dominio}:${porta}"

    # Simulação para dry-run
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] Simulação: ${dominio}:${porta} expira em 45 dias"
        return 0
    fi

    # Validação de dependência obrigatória
    valida_dep "openssl"

    local data_fim
    data_fim=$(echo | openssl s_client -servername "$dominio" -connect "${dominio}:${porta}" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2-)

    if [[ -z "$data_fim" ]]; then
        log_erro "Falha ao obter certificado de ${dominio}:${porta}"
        return 1
    fi

    local epoch_exp epoch_agora dias_restantes
    epoch_exp=$(date -d "$data_fim" +%s)
    epoch_agora=$(date +%s)
    dias_restantes=$(( (epoch_exp - epoch_agora) / 86400 ))

    if (( dias_restantes < 0 )); then
        log_erro "CERTIFICADO EXPIRADO: ${dominio} expirou há $(( -dias_restantes )) dias!"
        envia_alerta "CRITICAL" "Certificado de ${dominio} já expirou"
        return 2
    elif (( dias_restantes <= DIAS_ALERTA )); then
        log_warn "ALERTA: ${dominio} expira em ${dias_restantes} dias (limite: ${DIAS_ALERTA})"
        envia_alerta "WARN" "Certificado de ${dominio} expira em breve: ${dias_restantes} dias"
    else
        log_info "OK: ${dominio} expira em ${dias_restantes} dias (${data_fim})"
    fi

    return 0
}

# =============================================================================
# CHECKLIST DE VALIDAÇÃO
# =============================================================================
# 1. shellcheck comandos/ssl.sh → 0 avisos
# 2. bash -n comandos/ssl.sh → sintaxe ok
# 3. sre-toolkit ssl --help → uso exibido
# 4. sre-toolkit ssl -n google.com → dry-run não abre socket
# 5. sre-toolkit ssl -j google.com | jq . → json válido
