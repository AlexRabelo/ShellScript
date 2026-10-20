#!/usr/bin/env bash
#
# executa-em-hosts.sh - Executa comando em múltiplos hosts via SSH paralelo
# Útil para inventário, auditoria, deploy, coleta de logs em frota de servidores.
# Baseado no template de produção (módulo 10).
#
# Uso:
#   executa-em-hosts.sh [-n|--dry-run] [-v|--verbose] [-p|--paralelo N]
#                       [-t|--timeout S] [-u|--usuario USER] [-i|--identidade ARQ]
#                       [-f|--arquivo-hosts ARQ] [-h|--help] COMANDO
#
# Opções:
#   -n, --dry-run         Simula execução (mostra o que faria)
#   -v, --verbose         Log nível DEBUG
#   -p, --paralelo N      Execuções simultâneas (padrão: 10)
#   -t, --timeout S       Timeout SSH por host em segundos (padrão: 30)
#   -u, --usuario USER    Usuário SSH (padrão: usuário atual)
#   -i, --identidade ARQ  Chave SSH privada (padrão: agente/ssh-agent)
#   -f, --arquivo-hosts   Arquivo com lista de hosts (um por linha, # = comentário)
#   -h, --help            Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso (todos hosts OK) | 1 falha parcial | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   executa-em-hosts.sh "uptime"                           # Hosts de hosts.txt
#   executa-em-hosts.sh -f servidores.txt "df -h /"        # Arquivo customizado
#   executa-em-hosts.sh -p 5 -t 60 "systemctl status nginx" # 5 paralelos, 60s timeout
#   executa-em-hosts.sh -u admin -i ~/.ssh/id_rsa "uname -a" # User e chave customizados
#   executa-em-hosts.sh -n "reboot"                        # Dry-run: mostra hosts alvo
#
# Formato do arquivo de hosts (hosts.txt):
#   web01.exemplo.com
#   web02.exemplo.com
#   db01.exemplo.com     # comentários são ignorados
#   192.168.1.10         # IPs também funcionam

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
PARALELO=10
TIMEOUT=30
USUARIO_SSH="${USER}"
IDENTIDADE_SSH=""
ARQUIVO_HOSTS="hosts.txt"
COMANDO=""

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local prefixo=""
    [[ "$nivel" == "DRY-RUN" ]] && prefixo="[SIMULAÇÃO] "
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: ${prefixo}$*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      if [[ "$VERBOSE" -eq 1 ]]; then printf '%s\n' "$msg"; fi ;;
        DRY-RUN)    printf '%s\n' "$msg" ;;
        *)          printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }
log_dry()   { log "DRY-RUN" "$@"; }

die() {
    local codigo="${2:-1}"
    log_erro "$1"
    exit "$codigo"
}

# --- Limpeza -----------------------------------------------------------------
TMP_DIR=""
cleanup() {
    local codigo=$?
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf -- "$TMP_DIR"
    fi
    [[ $codigo -eq 0 ]] || log_erro "terminou com falha (código ${codigo})"
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM

# --- Utilidades --------------------------------------------------------------
requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

# Lê lista de hosts do arquivo (ignora linhas vazias e comentários)
ler_hosts() {
    local arquivo="$1"
    [[ -f "$arquivo" ]] || die "arquivo de hosts não encontrado: $arquivo" 1
    [[ -r "$arquivo" ]] || die "sem permissão de leitura: $arquivo" 1

    grep -v '^\s*#' "$arquivo" | grep -v '^\s*$' | sed 's/#.*$//' | sed 's/^\s*//;s/\s*$//'
}

# Executa comando em um host via SSH
executar_no_host() {
    local host="$1"
    local cmd="$2"
    local saida_arquivo="$3"
    local erro_arquivo="$4"

    local ssh_opts=(
        -o BatchMode=yes
        -o ConnectTimeout="$TIMEOUT"
        -o StrictHostKeyChecking=accept-new
        -o UserKnownHostsFile=/dev/null
        -o LogLevel=ERROR
    )

    [[ -n "$IDENTIDADE_SSH" ]] && ssh_opts+=(-i "$IDENTIDADE_SSH")

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_dry "ssh ${ssh_opts[*]} ${USUARIO_SSH}@${host} \"$cmd\""
        return 0
    fi

    local inicio fim duracao
    inicio=$(date +%s%3N)

    # Executa SSH capturando stdout/stderr separadamente
    ssh "${ssh_opts[@]}" "${USUARIO_SSH}@${host}" "$cmd" \
        > "$saida_arquivo" 2> "$erro_arquivo"
    local codigo=$?

    fim=$(date +%s%3N)
    duracao=$(( fim - inicio ))

    # Escreve metadados no arquivo de erro (última linha)
    echo "EXIT_CODE=$codigo" >> "$erro_arquivo"
    echo "DURATION_MS=$duracao" >> "$erro_arquivo"

    return $codigo
}

# Processa resultado de um host
processar_resultado() {
    local host="$1"
    local saida_arquivo="$2"
    local erro_arquivo="$3"

    local exit_code duracao
    exit_code=$(grep '^EXIT_CODE=' "$erro_arquivo" | cut -d= -f2)
    duracao=$(grep '^DURATION_MS=' "$erro_arquivo" | cut -d= -f2)
    exit_code="${exit_code:-1}"
    duracao="${duracao:-0}"

    # Remove linhas de metadados do stderr
    sed -i '/^EXIT_CODE=/d; /^DURATION_MS=/d' "$erro_arquivo"

    local saida erro
    saida=$(cat "$saida_arquivo" 2>/dev/null || true)
    erro=$(cat "$erro_arquivo" 2>/dev/null || true)

    if [[ $exit_code -eq 0 ]]; then
        log_info "[OK] $host (${duracao}ms)"
        [[ "$VERBOSE" -eq 1 && -n "$saida" ]] && echo "$saida" | sed 's/^/  /'
        return 0
    else
        log_erro "[FALHA] $host (exit=$exit_code, ${duracao}ms)"
        [[ -n "$erro" ]] && echo "$erro" | sed 's/^/  STDERR: /' >&2
        [[ -n "$saida" ]] && echo "$saida" | sed 's/^/  STDOUT: /' >&2
        return 1
    fi
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

# --- Lógica principal --------------------------------------------------------
main() {
    # Parse de opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -p|--paralelo) PARALELO="${2:-}"; shift 2 ;;
            -t|--timeout) TIMEOUT="${2:-}"; shift 2 ;;
            -u|--usuario) USUARIO_SSH="${2:-}"; shift 2 ;;
            -i|--identidade) IDENTIDADE_SSH="${2:-}"; shift 2 ;;
            -f|--arquivo-hosts) ARQUIVO_HOSTS="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

# Valida numéricos
    if [[ "$PARALELO" =~ ^[0-9]+$ ]] && (( PARALELO > 0 )); then
        :
    else
        die "paralelo deve ser número positivo: $PARALELO" 2
    fi
    if [[ "$TIMEOUT" =~ ^[0-9]+$ ]] && (( TIMEOUT > 0 )); then
        :
    else
        die "timeout deve ser número positivo: $TIMEOUT" 2
    fi

    # Comando obrigatório
    [[ $# -ge 1 ]] || { usage >&2; die "comando obrigatório" 2; }
    COMANDO="$*"

    # Pré-requisitos
    requer_comando ssh
    requer_comando xargs
    requer_comando mktemp

    [[ -f "$ARQUIVO_HOSTS" ]] || die "arquivo de hosts não encontrado: $ARQUIVO_HOSTS (use -f para especificar)" 1

    # Carrega hosts
    local hosts
    mapfile -t hosts < <(ler_hosts "$ARQUIVO_HOSTS")
    [[ ${#hosts[@]} -gt 0 ]] || die "nenhum host válido em $ARQUIVO_HOSTS" 1

    log_info "início (hosts=${#hosts[@]}, paralelo=$PARALELO, timeout=${TIMEOUT}s, user=$USUARIO_SSH, dry-run=$DRY_RUN)"
    log_debug "Comando: $COMANDO"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_dry "Hosts alvo:"
        for h in "${hosts[@]}"; do
            log_dry "  $h"
        done
        log_dry "Comando a executar: $COMANDO"
        log_info "fim (dry-run)"
        exit 0
    fi

    # Diretório temporário para outputs
    TMP_DIR="$(mktemp -d -t "${SCRIPT_NAME%.sh}.XXXXXX")"

    # Exporta variáveis para subprocessos xargs
    export SCRIPT_NAME LOG_FILE VERBOSE DRY_RUN USUARIO_SSH IDENTIDADE_SSH TIMEOUT TMP_DIR COMANDO

    # Função para xargs (precisa ser exportada)
    processar_host() {
        local host="$1"
        local saida="$TMP_DIR/${host//\//_}.out"
        local erro="$TMP_DIR/${host//\//_}.err"
        executar_no_host "$host" "$COMANDO" "$saida" "$erro"
        processar_resultado "$host" "$saida" "$erro"
    }
    export -f executar_no_host processar_resultado log log_info log_aviso log_erro log_debug log_dry

    # Executa em paralelo com xargs
    local falhas=0
    printf '%s\n' "${hosts[@]}" | xargs -P "$PARALELO" -I {} bash -c 'processar_host "$@"' _ {} || falhas=1

    # Resumo
    local sucessos=$(( ${#hosts[@]} - falhas ))
    log_info "Resumo: ${sucessos}/${#hosts[@]} sucessos, ${falhas} falhas"

    [[ $falhas -eq 0 ]] || exit 1
}

main "$@"