#!/usr/bin/env bash
#
# dry-run.sh - Demonstra modo dry-run (simulação) em scripts de produção
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   dry-run.sh [-n|--dry-run] [-v|--verbose] <ação> [alvo]
#
# Argumentos:
#   ACAO    Ação a executar: backup, limpeza, deploy, atualiza-config (obrigatório)
#   ALVO    Alvo da ação (opcional, depende da ação)
#
# Opções:
#   -n, --dry-run   Simula execução sem alterar estado
#   -v, --verbose   Habilita log nível DEBUG
#   -h, --help      Exibe esta ajuda
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico
#   2  Uso incorreto
#
# Exemplos:
#   ./dry-run.sh backup /etc                    # Executa backup real
#   ./dry-run.sh -n backup /etc                 # Simula backup (dry-run)
#   ./dry-run.sh -n -v limpeza /var/log         # Simula limpeza com debug
#   ./dry-run.sh deploy v1.2.3                  # Deploy real
#   ./dry-run.sh -n deploy v1.2.3               # Simula deploy completo
#   ./dry-run.sh atualiza-config /etc/app.conf  # Atualiza config real
#
# Demonstra:
#   - Padrão dry-run para scripts de produção
#   - Função central executar() que simula ou executa
#   - Rollback automático em deploy
#   - Validação de alvos antes da execução
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
ACAO=""
ALVO=""

log() {
    local nivel="$1"
    shift
    local prefixo=""
    [[ "$nivel" == "DRY-RUN" ]] && prefixo="[SIMULAÇÃO] "
    local msg
    msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: ${prefixo}$*"
    local ts
    ts=$(date '+%F %T')
    printf '%s\n' "$msg" >> "$LOG_FILE"
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$msg" ;;
        *)          printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO  "$@"; }
log_debug() { [[ "$VERBOSE" -eq 1 ]] && log DEBUG "$@"; }
log_dry()   { log "DRY-RUN" "$@"; }

# --- Função central: executa ou simula ---
executar() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_dry "$*"
        return 0
    else
        log_debug "Executando: $*"
        "$@"
    fi
}

# --- Validações ---
validar_alvo() {
    local alvo="$1"
    if [[ ! -e "$alvo" ]]; then
        log_erro "Alvo não existe: $alvo"
        return 1
    fi
    log_debug "Alvo validado: $alvo"
}

# --- Ações ---

acao_backup() {
    local origem
    origem="${ALVO:-/etc}"
    local destino
    destino="/tmp/backup-${SCRIPT_NAME%.sh}-$(date +%F-%H%M%S).tar.gz"

    log_info "=== AÇÃO: BACKUP ==="
    log_info "Origem: $origem"
    log_info "Destino: $destino"

    validar_alvo "$origem" || return 1

    executar tar -czf "$destino" -C "$(dirname "$origem")" "$(basename "$origem")"

    if [[ "$DRY_RUN" -eq 0 ]]; then
        local tamanho
        tamanho=$(du -h "$destino" | cut -f1)
        log_info "Backup criado: $destino ($tamanho)"
        log_info "Verificação de integridade:"
        executar sha256sum "$destino"
    fi
}

acao_limpeza() {
    local alvo
    alvo="${ALVO:-/tmp}"
    local padrao="*.tmp"
    local dias=7

    log_info "=== AÇÃO: LIMPEZA ==="
    log_info "Diretório: $alvo"
    log_info "Padrão: $padrao"
    log_info "Arquivos com mais de $dias dias"

    validar_alvo "$alvo" || return 1

    # Encontra arquivos (dry-run mostra o que seria apagado)
    local arquivos
    mapfile -t arquivos < <(find "$alvo" -name "$padrao" -type f -mtime +"$dias" 2>/dev/null)

    if [[ ${#arquivos[@]} -eq 0 ]]; then
        log_info "Nenhum arquivo para limpar"
        return 0
    fi

    log_info "Arquivos que seriam removidos (${#arquivos[@]}):"
    for arq in "${arquivos[@]}"; do
        local tamanho
        tamanho=$(du -h "$arq" | cut -f1)
        log_dry "  rm -f $arq ($tamanho)"
    done

    if [[ "$DRY_RUN" -eq 0 ]]; then
        log_info "Removendo arquivos..."
        for arq in "${arquivos[@]}"; do
            executar rm -f "$arq"
        done
        log_info "Limpeza concluída"
    fi
}

acao_deploy() {
    local versao
    versao="${ALVO:-latest}"
    local app_dir="/opt/meu-app"
    local backup_dir="/opt/backups/meu-app"

    log_info "=== AÇÃO: DEPLOY ==="
    log_info "Versão: $versao"
    log_info "Diretório da aplicação: $app_dir"

    # Passo 1: Backup da versão atual
    log_info "Passo 1: Backup da versão atual"
    if [[ -d "$app_dir" ]]; then
        local backup_atual
        backup_atual="${backup_dir}/pre-deploy-$(date +%F-%H%M%S)"
        executar mkdir -p "$backup_dir"
        executar cp -a "$app_dir" "$backup_atual"
        log_dry "Backup salvo em: $backup_atual"
    fi

    # Passo 2: Baixa nova versão (simulado)
    log_info "Passo 2: Baixando versão $versao"
    executar curl -sfL "https://exemplo.com/app-$versao.tar.gz" -o "/tmp/app-$versao.tar.gz"

    # Passo 3: Extrai e substitui
    log_info "Passo 3: Instalando nova versão"
    executar rm -rf "$app_dir"
    executar mkdir -p "$app_dir"
    executar tar -xzf "/tmp/app-$versao.tar.gz" -C "$app_dir"

    # Passo 4: Validação pós-deploy
    log_info "Passo 4: Validação (healthcheck)"
    executar "$app_dir/bin/healthcheck" || {
        log_erro "Healthcheck falhou! Iniciando rollback..."
        if [[ "$DRY_RUN" -eq 0 && -d "$backup_atual" ]]; then
            executar rm -rf "$app_dir"
            executar mv "$backup_atual" "$app_dir"
            log_aviso "Rollback concluído"
        fi
        return 1
    }

    log_info "Deploy concluído com sucesso"
}

acao_atualiza_config() {
    local arquivo
    arquivo="${ALVO:-/etc/meu-app/config.conf}"
    local chave="max_connections"
    local valor="200"

    log_info "=== AÇÃO: ATUALIZA CONFIGURAÇÃO ==="
    log_info "Arquivo: $arquivo"
    log_info "Chave: $chave = $valor"

    validar_alvo "$arquivo" || return 1

    # Backup do original
    local backup
    backup="${arquivo}.bak.$(date +%F-%H%M%S)"
    executar cp -a "$arquivo" "$backup"
    log_dry "Backup: $backup"

    # Atualiza ou adiciona a chave
    if grep -q "^${chave}=" "$arquivo"; then
        log_info "Chave existe - atualizando valor"
        executar sed -i "s/^${chave}=.*/${chave}=${valor}/" "$arquivo"
    else
        log_info "Chave não existe - adicionando"
        executar echo "${chave}=${valor}" >> "$arquivo"
    fi

    # Valida sintaxe (exemplo genérico)
    log_info "Validando sintaxe..."
    if [[ "$DRY_RUN" -eq 0 ]]; then
        # Simula validação - em produção seria: nginx -t, apachectl configtest, etc.
        true
    fi
    log_dry "Validação: OK"

    log_info "Configuração atualizada"
}

# --- Help ---
usage() {
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

# --- Parse de argumentos ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_erro "Opção desconhecida: $1"
                usage >&2
                exit 2
                ;;
            *)
                if [[ -z "$ACAO" ]]; then
                    ACAO="$1"
                elif [[ -z "$ALVO" ]]; then
                    ALVO="$1"
                else
                    log_erro "Argumento extra: $1"
                    usage >&2
                    exit 2
                fi
                shift
                ;;
        esac
    done

    [[ -n "$ACAO" ]] || { log_erro "Ação obrigatória"; usage >&2; exit 2; }
}

# --- Lógica Principal --------------------------------------------------------
main() {
    parse_args "$@"

    log_info "=== INÍCIO: $SCRIPT_NAME ==="
    log_info "Modo: $([[ $DRY_RUN -eq 1 ]] && echo 'DRY-RUN (simulação)' || echo 'EXECUÇÃO REAL')"
    log_info "Verboso: $([[ $VERBOSE -eq 1 ]] && echo 'sim' || echo 'não')"
    log_info "Ação: $ACAO"
    [[ -n "$ALVO" ]] && log_info "Alvo: $ALVO"

    case "$ACAO" in
        backup)
            acao_backup
            ;;
        limpeza)
            acao_limpeza
            ;;
        deploy)
            acao_deploy
            ;;
        atualiza-config)
            acao_atualiza_config
            ;;
        *)
            log_erro "Ação desconhecida: $ACAO"
            usage >&2
            exit 2
            ;;
    esac

    log_info "=== FIM: $SCRIPT_NAME ==="
}

main "$@"