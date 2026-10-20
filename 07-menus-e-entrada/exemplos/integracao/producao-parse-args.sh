#!/usr/bin/env bash
# producao-parse-args.sh — Parsing robusto com validação (nível produção)
# Conceitos: Módulo 02 (variáveis) + Módulo 10 (template produção)

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
SERVIDORES=()
PORTA=443
AMBIENTE="producao"

log() {
    local nivel="$1"; shift
    local msg
    msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    case "$nivel" in ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG) [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$msg" ;;
        *) printf '%s\n' "$msg" ;;
    esac
}
log_info() { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro() { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }

usage() {
    cat <<EOF
${SCRIPT_NAME} - Processa lista de servidores com validação

Uso: ${SCRIPT_NAME} [-p PORTA] [-a AMBIENTE] [-n] [-v] SERVIDOR [SERVIDOR...]

Opções:
  -p PORTA       Porta alvo (padrão: 443)
  -a AMBIENTE    Ambiente: producao|homolog|dev (padrão: producao)
  -n, --dry-run  Simula
  -v, --verbose  Verboso
  -h, --help     Ajuda

Exemplos:
  ${SCRIPT_NAME} web01 web02
  ${SCRIPT_NAME} -p 80 -a homolog app01 app02 app03
  ${SCRIPT_NAME} -n -v db01
EOF
}

valida_porta() {
    if [[ "$1" =~ ^[0-9]+$ ]] && (( 1 <= $1 && $1 <= 65535 )); then
        return 0
    else
        die "Porta inválida: $1" 2
    fi
}

valida_ambiente() {
    if [[ "$1" =~ ^(producao|homolog|dev)$ ]]; then
        return 0
    else
        die "Ambiente inválido: $1 (use producao|homolog|dev)" 2
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p) PORTA="${2:-}"; valida_porta "$PORTA"; shift 2 ;;
            -a) AMBIENTE="${2:-}"; valida_ambiente "$AMBIENTE"; shift 2 ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "Opção desconhecida: $1" 2 ;;
            *) SERVIDORES+=("$1"); shift ;;
        esac
    done

    [[ ${#SERVIDORES[@]} -ge 1 ]] || { usage >&2; die "Informe ao menos 1 servidor" 2; }

    requer_comando ping
    log_info "início (servidores=${#SERVIDORES[@]}, porta=$PORTA, ambiente=$AMBIENTE, dry-run=$DRY_RUN)"

    for srv in "${SERVIDORES[@]}"; do
        log_info "Processando: $srv"
        if (( DRY_RUN == 1 )); then
            log_info "[DRY-RUN] ping -c 1 -W 2 $srv"
        else
            if ping -c 1 -W 2 "$srv" >/dev/null 2>&1; then
                log_info "  $srv: ONLINE"
            else
                log_aviso "  $srv: OFFLINE"
            fi
        fi
    done

    log_info "fim"
}

main "$@"