#!/usr/bin/env bash
#
# inventario-frota.sh - Inventário de frota de servidores via SSH paralelo
# Usa executa-em-hosts.sh como biblioteca para coletar informações padronizadas.
#
# Uso:
#   inventario-frota.sh [-f|--arquivo-hosts ARQ] [-p|--paralelo N]
#                      [-t|--timeout S] [-o|--output ARQ] [-j|--json]
#                      [-u|--usuario USER] [-i|--identidade ARQ] [-h|--help]
#
# Opções:
#   -f, --arquivo-hosts ARQ  Arquivo com hosts (padrão: hosts.txt)
#   -p, --paralelo N         Execuções simultâneas (padrão: 10)
#   -t, --timeout S          Timeout SSH por host (padrão: 30)
#   -o, --output ARQ         Arquivo de saída (padrão: stdout)
#   -j, --json               Saída JSON (padrão: texto com progress bar)
#   -u, --usuario USER       Usuário SSH (padrão: atual)
#   -i, --identidade ARQ     Chave SSH privada
#   -h, --help               Exibe esta ajuda
#
# Códigos de saída:
#   0 sucesso | 1 falha parcial | 2 uso incorreto | 3 pré-requisito
#
# Exemplos:
#   inventario-frota.sh                          # Texto, hosts.txt
#   inventario-frota.sh -f frota.txt -o inv.json # JSON em arquivo
#   inventario-frota.sh -p 5 -t 60 -u admin      # 5 paralelos, 60s timeout

# --- Modo estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

ARQUIVO_HOSTS="hosts.txt"
PARALELO=10
TIMEOUT=30
OUTPUT_FILE=""
JSON_OUTPUT=0
USUARIO_SSH="${USER}"
IDENTIDADE_SSH=""

# Cores para saída texto
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m'

# --- Log ---------------------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null || true
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$msg" >&2 ;;
        *)          [[ "$JSON_OUTPUT" -eq 0 ]] && printf '%s\n' "$msg" ;;
    esac
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() {
    local codigo="${2:-1}"
    log_erro "$1"
    exit "$codigo"
}

# --- Limpeza -----------------------------------------------------------------
cleanup() {
    local codigo=$?
    [[ $codigo -eq 0 ]] || log_erro "terminou com falha (código ${codigo})"
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades --------------------------------------------------------------
requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

# Comando de coleta remota (heredoc para legibilidade)
COMANDO_COLETA=$(cat << 'EOF_COLETA'
# --- Coleta de dados do host remoto ---
hostname=$(hostname)
uptime_sec=$(cut -d. -f1 /proc/uptime)
kernel=$(uname -r)

# Distro
if [[ -f /etc/os-release ]]; then
    distro=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
else
    distro="desconhecido"
fi

# CPU
cpu_modelo=$(lscpu 2>/dev/null | grep "Model name:" | cut -d: -f2 | sed 's/^ *//' || echo "desconhecido")
cpu_nucleos=$(lscpu 2>/dev/null | grep "^CPU(s):" | awk '{print $2}' || echo "?")
cpu_carga=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')

# Memória
mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_livre_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
mem_usada_kb=$(( mem_total_kb - mem_livre_kb ))
mem_pct=0
[[ $mem_total_kb -gt 0 ]] && mem_pct=$(( mem_usada_kb * 100 / mem_total_kb ))

swap_total_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
swap_livre_kb=$(grep SwapFree /proc/meminfo | awk '{print $2}')
swap_usada_kb=$(( swap_total_kb - swap_livre_kb ))
swap_pct=0
[[ $swap_total_kb -gt 0 ]] && swap_pct=$(( swap_usada_kb * 100 / swap_total_kb ))

# Disco
disco_raiz=$(df -P / | tail -1)
disco_var=""
if [[ -d /var ]]; then
    disco_var=$(df -P /var | tail -1)
fi

# Serviços ativos
servicos=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | awk '{print $1}' | paste -sd, - || echo "")

# Pacotes
if command -v dpkg >/dev/null 2>&1; then
    pacotes=$(dpkg -l 2>/dev/null | grep ^ii | wc -l)
elif command -v rpm >/dev/null 2>&1; then
    pacotes=$(rpm -qa 2>/dev/null | wc -l)
else
    pacotes=0
fi

# Saída JSON único por host
jq -n \
    --arg hostname "$hostname" \
    --arg uptime "$uptime_sec" \
    --arg kernel "$kernel" \
    --arg distro "$distro" \
    --arg cpu_modelo "$cpu_modelo" \
    --arg cpu_nucleos "$cpu_nucleos" \
    --arg cpu_carga "$cpu_carga" \
    --argjson mem_total "$mem_total_kb" \
    --argjson mem_usada "$mem_usada_kb" \
    --argjson mem_pct "$mem_pct" \
    --argjson swap_total "$swap_total_kb" \
    --argjson swap_usada "$swap_usada_kb" \
    --argjson swap_pct "$swap_pct" \
    --arg disco_raiz "$disco_raiz" \
    --arg disco_var "$disco_var" \
    --arg servicos "$servicos" \
    --argjson pacotes "$pacotes" \
    --arg timestamp "$(date -Iseconds)" \
    --arg erro "" \
    '{
        hostname: $hostname,
        uptime_segundos: ($uptime|tonumber),
        kernel: $kernel,
        distro: $distro,
        cpu: {modelo: $cpu_modelo, nucleos: ($cpu_nucleos|tonumber), carga: $cpu_carga},
        memoria: {total_kb: $mem_total, usada_kb: $mem_usada, uso_pct: $mem_pct, swap_total_kb: $swap_total, swap_usada_kb: $swap_usada, swap_pct: $swap_pct},
        disco: {raiz: $disco_raiz, var: $disco_var},
        servicos_ativos: $servicos,
        pacotes_instalados: $pacotes,
        timestamp: $timestamp,
        erro: $erro
    }'
EOF_COLETA
)

# --- Progress bar simples ---
show_progress() {
    local atual="$1" total="$2" host="$3"
    [[ "$JSON_OUTPUT" -eq 1 ]] && return
    [[ ! -t 1 ]] && return
    local pct=$(( atual * 100 / total ))
    local bar_len=30
    local filled=$(( pct * bar_len / 100 ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<bar_len; i++)); do bar+="░"; done
    printf '\r[%s] %3d%% (%d/%d) %s' "$bar" "$pct" "$atual" "$total" "$host"
}

# --- Ajuda -------------------------------------------------------------------
usage() {
    sed -n '3,21p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Main --------------------------------------------------------------------
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--arquivo-hosts) ARQUIVO_HOSTS="${2:-}"; shift 2 ;;
            -p|--paralelo) PARALELO="${2:-}"; shift 2 ;;
            -t|--timeout) TIMEOUT="${2:-}"; shift 2 ;;
            -o|--output) OUTPUT_FILE="${2:-}"; shift 2 ;;
            -j|--json) JSON_OUTPUT=1; shift ;;
            -u|--usuario) USUARIO_SSH="${2:-}"; shift 2 ;;
            -i|--identidade) IDENTIDADE_SSH="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) die "argumento não esperado: $1" 2 ;;
        esac
    done

    [[ "$PARALELO" =~ ^[0-9]+$ ]] && (( PARALELO > 0 )) || die "paralelo deve ser número positivo: $PARALELO" 2
    [[ "$TIMEOUT" =~ ^[0-9]+$ ]] && (( TIMEOUT > 0 )) || die "timeout deve ser número positivo: $TIMEOUT" 2

    # Pré-requisitos
    requer_comando jq
    requer_comando ssh

    [[ -f "$ARQUIVO_HOSTS" ]] || die "arquivo de hosts não encontrado: $ARQUIVO_HOSTS" 1

    # Carrega hosts
    local hosts
    mapfile -t hosts < <(grep -v '^\s*#' "$ARQUIVO_HOSTS" | grep -v '^\s*$' | sed 's/#.*$//' | sed 's/^\s*//;s/\s*$//')
    [[ ${#hosts[@]} -gt 0 ]] || die "nenhum host válido em $ARQUIVO_HOSTS" 1

    log_info "início (hosts=${#hosts[@]}, paralelo=$PARALELO, timeout=${TIMEOUT}s, json=$JSON_OUTPUT)"

    # Prepara comando SSH base
    local ssh_opts=(-o BatchMode=yes -o ConnectTimeout="$TIMEOUT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
    [[ -n "$IDENTIDADE_SSH" ]] && ssh_opts+=(-i "$IDENTIDADE_SSH")

    # Diretório temporário para resultados
    local tmp_dir
    tmp_dir=$(mktemp -d -t "${SCRIPT_NAME%.sh}.XXXXXX")

    # Exporta para subprocessos
    export USUARIO_SSH IDENTIDADE_SSH TIMEOUT tmp_dir COMANDO_COLETA JSON_OUTPUT

    # Função para coletar de um host
    coletar_host() {
        local host="$1"
        local outfile="$tmp_dir/${host//\//_}.json"
        local errfile="$tmp_dir/${host//\//_}.err"

        local cmd="ssh ${ssh_opts[*]} ${USUARIO_SSH}@${host} \"$COMANDO_COLETA\""
        if eval "$cmd" > "$outfile" 2> "$errfile"; then
            echo "OK:$host" >&2
        else
            local erro_msg
            erro_msg=$(cat "$errfile" 2>/dev/null | head -1 || echo "falha_desconhecida")
            # Cria JSON de erro
            jq -n \
                --arg hostname "$host" \
                --arg erro "$erro_msg" \
                --arg timestamp "$(date -Iseconds)" \
                '{hostname: $hostname, erro: $erro, timestamp: $timestamp}' > "$outfile"
            echo "ERRO:$host" >&2
        fi
    }
    export -f coletar_host

    # Executa em paralelo
    local resultados=()
    local sucessos=0 falhas=0
    local processados=0

    # Usa xargs para paralelismo
    printf '%s\n' "${hosts[@]}" | xargs -P "$PARALELO" -I {} bash -c 'coletar_host "$@"' _ {} 2>&1 | while IFS= read -r linha; do
        if [[ "$linha" == OK:* ]]; then
            ((sucessos++))
        elif [[ "$linha" == ERRO:* ]]; then
            ((falhas++))
        fi
        ((processados++))
        show_progress "$processados" "${#hosts[@]}" "${linha#*:}"
    done

    [[ "$JSON_OUTPUT" -eq 0 && -t 1 ]] && echo

    # Consolida resultados
    local json_final="[]"
    for host in "${hosts[@]}"; do
        local outfile="$tmp_dir/${host//\//_}.json"
        if [[ -f "$outfile" ]]; then
            local host_json
            host_json=$(cat "$outfile")
            json_final=$(echo "$json_final" | jq -c --argjson h "$host_json" '. + [$h]')
        fi
    done

    local resultado_json
    resultado_json=$(jq -n --argjson hosts "$json_final" --arg timestamp "$(date -Iseconds)" '{timestamp: $timestamp, total: ($hosts|length), hosts: $hosts}')

    # Saída
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$resultado_json" > "$OUTPUT_FILE"
        log_info "Resultado salvo em: $OUTPUT_FILE"
    else
        echo "$resultado_json"
    fi

    if [[ "$JSON_OUTPUT" -eq 0 ]]; then
        log_info "Resumo: ${sucessos} sucessos, ${falhas} falhas de ${#hosts[@]} hosts"
    fi

    # Cleanup temp dir
    rm -rf "$tmp_dir"

    [[ $falhas -eq 0 ]] || exit 1
}

main "$@"