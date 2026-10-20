#!/usr/bin/env bash
#
# renomeador-inteligente.sh - Renomeia lotes com padrões inteligentes
#
# Uso: ./renomeador-inteligente.sh [-n] [-v] [-e EXT] -p PADRAO ARQUIVOS...
#
# Renomeia arquivos usando padrões com variáveis substituíveis:
#   {n}  → número sequencial (001, 002, ...)
#   {t}  → timestamp (YYYYMMDD-HHMMSS)
#   {h}  → hostname curto
#   {f}  → nome original do arquivo (sem extensão)
#   {e}  → extensão original
#
# Exemplo:
#   ./renomeador-inteligente.sh -p "{t}_{f}" foto.jpg foto.png
#   # → 20261013-103045_foto.jpg 20261013-103045_foto.png
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# =============================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME
SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE
LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
EXTENSOES=""  # lista separada por vírgula (ex: jpg,png)
PADRAO=""     # padrão de renomeação obrigatório

log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg
    msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO "$@" >&2; }

die() {
    local msg="$1"
    local codigo
    codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

cleanup() {
    local codigo=$?
    if [[ $codigo -eq 0 ]]; then
        log_info "terminou com sucesso"
    else
        log_erro "terminou com falha (código ${codigo})"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

usage() {
    sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'
}

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

# Funções auxiliares
get_timestamp() {
    date '+%Y%m%d-%H%M%S'
}

get_hostname() {
    hostname -s 2>/dev/null || hostname 2>/dev/null || echo "localhost"
}

expande_padrao() {
    local arquivo="$1"
    local padrao="$2"
    local seq_num="$3"  # número sequencial para {n}
    
    # Separa nome e extensão
    local nome_base
    nome_base="${arquivo%.*}"
    local extensao
    extensao="${arquivo##*.}"
    [[ "$arquivo" == *.* ]] || extensao=""  # sem extensão
    
    # Substitui variáveis no padrão
    padrao="${padrao//\{n\}/$(printf "%03d" "$seq_num")}"
    padrao="${padrao//\{t\}/$(get_timestamp)}"
    padrao="${padrao//\{h\}/$(get_hostname)}"
    padrao="${padrao//\{f\}/$nome_base}"
    padrao="${padrao//\{e\}/$extensao}"
    
    echo "$padrao"
}

main() {
    # Processa opções
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -e|--ext)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -e" 2
                EXTENSOES="$2"; shift 2 ;;
            -p|--padrao)
                [[ -n "${2:-}" ]] || die "Argumento obrigatório para -p" 2
                PADRAO="$2"; shift 2 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    # Validação
    [[ -n "$PADRAO" ]] || die "Padrão de renomeação é obrigatório (use -p PADRAO)" 2
    [[ $# -gt 0 ]] || die "Nenhum arquivo especificado" 2

    requer_comando date
    requer_comando hostname || true  # não é fatal

    log_info "início (dry-run=$DRY_RUN, extensoes='$EXTENSOES', padrao='$PADRAO', ${#@} arquivos)"

    # Processa cada arquivo
    local seq=1
    local erro=0

    for arquivo in "$@"; do
        [[ -e "$arquivo" ]] || { log_aviso "arquivo não encontrado: $arquivo"; erro=1; continue; }
        [[ -f "$arquivo" ]] || { log_aviso "não é um arquivo regular: $arquivo"; erro=1; continue; }

        # Filtra por extensão se especificado
        if [[ -n "$EXTENSOES" ]]; then
            local extensao_atual
            extensao_atual="${arquivo##*.}"
            [[ "$arquivo" == *.* ]] || extensao_atual=""  # sem extensão
            local encontrou=0
            IFS=',' read -ra ext_array <<< "$EXTENSOES"
            for ext in "${ext_array[@]}"; do
                [[ "$extensao_atual" == "$ext" ]] && encontrou=1 && break
            done
            (( encontrou )) || continue
        fi

        # Gera novo nome
        local novo_nome
        novo_nome=$(expande_padrao "$arquivo" "$PADRAO" "$seq")
        (( seq++ ))

        # Verifica conflito
        [[ -e "$novo_nome" ]] && { log_erro "arquivo de destino já existe: $novo_nome"; erro=1; continue; }

        # Executa ou simula
        if (( DRY_RUN )); then
            log_info "[DRY-RUN] $arquivo → $novo_nome"
        else
            mv -- "$arquivo" "$novo_nome"
            log_info "renomeado: $arquivo → $novo_nome"
        fi
    done

    (( erro )) && die "processado com erros" 1
    log_info "fim"
}

main "$@"