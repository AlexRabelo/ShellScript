#!/usr/bin/env bash
#
# expansao-avancada-corrigido.sh - Processa nomes de arquivo com expansão de parâmetro
#
# Uso: ./expansao-avancada-corrigido.sh
#
# Processa lista de extensões e nomes de arquivo demonstrando expansão de parâmetro segura.
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
    sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
    log_info "início"

    # Lista de arquivos com aspas corretas
    local arquivos="foto.JPG imagem.PNG documento.PDF plano.XLSX"
    
    # Processa cada extensão
    local ext
    for ext in jpg png pdf xlsx; do
        local count=0
        # Usa array para evitar word splitting
        local arr=()
        IFS=' ' read -r -a arr <<< "$arquivos"
        for arq in "${arr[@]}"; do
            # Comparação segura com aspas
            if [[ "$arq" == *.$ext ]]; then
                ((count++))
            fi
        done
        printf 'Extensão %s: %d arquivos\n' "$ext" "$count"
    done

    # Processamento de nome de arquivo
    local nome_foto="FERIAS_FAMILIA_2026.JPG"
    local nome_lower
    nome_lower=${nome_foto,,}           # minúsculas
    local nome_sem_ext
    nome_sem_ext=${nome_lower%.*}       # remove extensão
    local ext
    ext=${nome_lower##*.}               # pega extensão

    log_info "nome_foto=$nome_foto"
    log_info "nome_lower=$nome_lower"
    log_info "nome_sem_ext=$nome_sem_ext"
    log_info "ext=$ext"

    # Nome novo com validação
    local novo_nome="familia_ferias_2026.$ext"
    if [[ -f "$novo_nome" ]]; then
        die "ERRO: arquivo já existe: $novo_nome" 1
    fi

    # Operação segura
    if [[ -e "$nome_foto" ]]; then
        mv -- "$nome_foto" "$novo_nome"
        log_info "Renomeado para: $novo_nome"
    else
        log_aviso "arquivo de origem não existe (simulação): $nome_foto"
        # Em ambiente real, faria o mv aqui
    fi

    log_info "fim"
}

main "$@"