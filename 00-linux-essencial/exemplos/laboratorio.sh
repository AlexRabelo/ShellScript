#!/usr/bin/env bash
#
# laboratorio.sh - Demonstração guiada dos comandos essenciais do Linux (Módulo 00)
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   laboratorio.sh
#
# Descrição:
#   Cria uma área de testes em /tmp/lab-linux e demonstra comandos básicos
#   de navegação, manipulação de arquivos, permissões, pipes e redirecionamentos.
#   Seguro: só opera dentro de /tmp/lab-linux.
#
# Exemplos:
#   ./laboratorio.sh
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

# --- Funções de Log ----------------------------------------------------------
log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

# --- Limpeza e Tratamento de Sinais ------------------------------------------
cleanup() {
    local codigo=$?
    if [[ $codigo -eq 0 ]]; then
        log_info "terminou com sucesso"
    else
        log_erro "terminou com falha (código ${codigo})"
    fi
}
trap cleanup EXIT
trap 'log_erro "interrompido pelo usuário"; exit 130' INT
trap 'log_erro "recebeu sinal de término"; exit 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades --------------------------------------------------------------
requer_comando() {
    command -v "$1" > /dev/null 2>&1 || { log_erro "comando obrigatório não encontrado: $1"; exit 3; }
}

# --- Lógica Principal --------------------------------------------------------
main() {
    log_info "início"

    # Recomeça do zero a cada execução
    rm -rf /tmp/lab-linux
    mkdir -p /tmp/lab-linux/logs /tmp/lab-linux/backup
    cd /tmp/lab-linux || exit 1

    log_info "1. Onde estou?"
    pwd

    echo
    log_info "2. Criando arquivos"
    touch notas.txt
    echo "primeira linha" > notas.txt        # > sobrescreve
    echo "segunda linha" >> notas.txt        # >> acrescenta
    echo "terceira linha" >> notas.txt
    cat notas.txt

    echo
    log_info "3. Um log de exemplo"
    echo "INFO  servico iniciado"   > logs/app.log
    {
        echo "INFO  iniciando monitoramento"
        echo "ERRO  falha ao conectar"
        echo "INFO  finalizando"
    } >> logs/app.log
    cat logs/app.log

    echo
    log_info "4. Filtrando com grep"
    grep -c "ERRO" logs/app.log

    echo
    log_info "5. Pipe: quantas linhas de ERRO?"
    grep -c "ERRO" logs/app.log

    echo
    log_info "6. Copiando e movendo"
    cp notas.txt backup/notas.bak
    mv notas.txt anotacoes.txt
    ls -l . backup

    echo
    log_info "7. Permissões"
    touch executavel.sh
    ls -l executavel.sh
    chmod 755 executavel.sh
    ls -l executavel.sh

    echo
    log_info "8. Redirecionando erros"
    ls /pasta-que-nao-existe 2> logs/erros.txt
    echo "Conteúdo de erros.txt:"
    cat logs/erros.txt

    echo
    log_info "9. Procurando arquivos"
    find /tmp/lab-linux -name "*.txt"

    echo
    log_info "Pronto. Explore a pasta /tmp/lab-linux e apague com: rm -rf /tmp/lab-linux"

    log_info "fim"
}

main "$@"