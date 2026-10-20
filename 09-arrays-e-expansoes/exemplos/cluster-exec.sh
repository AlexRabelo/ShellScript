#!/usr/bin/env bash
#
# cluster-exec.sh - executa comando em múltiplos servidores usando arrays.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   cluster-exec.sh [-t TIMEOUT] [-u USUARIO] COMANDO SERVIDOR1 [SERVIDOR2 ...]
#
# Executa um comando em múltiplos servidores via SSH, coletando resultados.
# Usa arrays para gerenciar a lista de servidores e processar resultados.
#
# Opções:
#   -t TIMEOUT  timeout SSH em segundos (padrão: 10)
#   -u USUARIO  usuário SSH (padrão: usuário atual)
#   -h          ajuda
#
# Exemplo:
#   cluster-exec.sh "uptime" server1 server2 server3
#   cluster-exec.sh -t 5 -u admin "df -h /" node01 node02
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0
TIMEOUT=10
USUARIO="${USER}"

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

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

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

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] $*"
        return 0
    else
        log_debug "executando: $*"
        "$@"
    fi
}

usage() {
    sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -t|--timeout) TIMEOUT="$2"; shift 2 ;;
            -u|--usuario) USUARIO="$2"; shift 2 ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    # Validação de argumentos vai aqui
    # Exemplo: [[ $# -eq 2 ]] || { usage >&2; die "forneça exatamente 2 argumentos" 2; }

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE, timeout=$TIMEOUT, usuario=$USUARIO)"

    # Lógica principal do script vai aqui
    # Exemplo:
    # for arg in "$@"; do
    #     log_info "Processando: $arg"
    # done

    [[ $# -ge 2 ]] || { usage >&2; die "forneça pelo menos 2 argumentos (comando e pelo menos 1 servidor)" 2; }

    # Valida se TIMEOUT é um número positivo
    [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || die "TIMEOUT deve ser um número inteiro positivo" 2
    [[ "$TIMEOUT" -gt 0 ]] || die "TIMEOUT deve ser maior que zero" 2

    local comando="$1"
    shift
    local servidores=("$@")

    [[ -n "$comando" ]] || die "comando não pode estar vazio" 2
    [[ ${#servidores[@]} -gt 0 ]] || die "lista de servidores não pode estar vazia" 2

    echo "=== Execução em Cluster ==="
    echo "Comando: $comando"
    echo "Timeout: ${TIMEOUT}s"
    echo "Usuário: $USUARIO"
    echo "Servidores: ${#servidores[@]}"
    echo

    local sucessos=0
    local falhas=0
    local resultados=()

    for servidor in "${servidores[@]}"; do
        echo -n "[$servidor] "

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "[DRY-RUN] ssh -o ConnectTimeout=$TIMEOUT -o BatchMode=yes $USUARIO@$servidor \"$comando\""
            echo "[DRY-RUN]"
            ((sucessos++))
        else
            # Executa o comando via SSH com timeout
            local resultado
            local codigo_saida

            resultado=$(ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$USUARIO@$servidor" "$comando" 2>&1)
            codigo_saida=$?

            if [[ $codigo_saida -eq 0 ]]; then
                echo "✓ SUCESSO"
                echo "$resultado" | sed 's/^/    /'
                ((sucessos++))
                resultados+=("[${servidor}] SUCESSO: $resultado")
            else
                echo "✗ FALHA (código $codigo_saida)"
                echo "$resultado" | sed 's/^/    /' >&2
                ((falhas++))
                resultados+=("[${servidor}] FALHA: $resultado")
            fi
        fi

        echo
    done

    echo "=== RESUMO ==="
    echo "Total de servidores: ${#servidores[@]}"
    echo "Sucessos: $sucessos"
    echo "Falhas: $falhas"

    if [[ $falhas -gt 0 ]]; then
        echo "Falhas detectadas - verifique a saída acima para detalhes"
        exit 1
    fi

    log_info "fim"
}

main "$@"