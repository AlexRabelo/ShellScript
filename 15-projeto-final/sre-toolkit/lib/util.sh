#!/usr/bin/env bash
#
# lib/util.sh - Utilitários comuns para sre-toolkit

# Executa comando ou simula no dry-run
run() {
    if (( ${DRY_RUN:-0} == 1 )); then
        log_info "[DRY-RUN] $*"
        return 0
    else
        log_debug "Executando: $*"
        "$@"
    fi
}

# Lock com flock
lock_obter() {
    local lock_file="$1" timeout="${2:-0}"
    local fd=200
    eval "exec ${fd}> \"$lock_file\""
    if (( timeout > 0 )); then
        flock -w "$timeout" "$fd" || return 1
    else
        flock -n "$fd" || return 1
    fi
    echo $$ >&"$fd"
    echo "$fd"
}

lock_liberar() {
    local fd="$1"
    eval "exec ${fd}>&-"
}

# Diretório temporário com limpeza automática
tmp_criar() {
    local prefix="${1:-sre-toolkit}"
    mktemp -d -t "${prefix}.XXXXXX"
}

tmp_limpar() {
    local dir="$1"
    [[ -d "$dir" ]] && rm -rf -- "$dir"
}

# Formata bytes em humano
bytes_humano() {
    local b="${1:-0}" unidades=(B KB MB GB TB) i=0
    while (( b >= 1024 && i < ${#unidades[@]} - 1 )); do
        b=$(( b / 1024 )); ((i++))
    done
    echo "${b} ${unidades[i]}"
}

# Timestamp ISO8601 UTC
timestamp_iso() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# Hostname curto
host_curto() {
    hostname -s 2>/dev/null || hostname | cut -d. -f1 || hostname
}

# Parse de opções genérico (retorna args não-opções em array REST_ARGS)
parse_opts() {
    local opts="$1"; shift
    local -n _args=$1; shift
    REST_ARGS=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*) 
                local opt="$1"
                if [[ "$opts" == *"${opt#-}"* ]]; then
                    _args+=("$1")
                    [[ $# -gt 1 && "$2" != -* ]] && { _args+=("$2"); shift; }
                else
                    log_erro "Opção desconhecida: $1"; return 2
                fi
                ;;
            *) REST_ARGS+=("$1") ;;
        esac
        shift
    done
}

# Verifica se comando existe
tem_comando() { command -v "$1" >/dev/null 2>&1; }

# Timeout wrapper
com_timeout() {
    local timeout="$1"; shift
    timeout "$timeout" "$@" || {
        local code=$?
        (( code == 124 )) && log_aviso "Timeout ($timeout s) atingido: $*"
        return $code
    }
}