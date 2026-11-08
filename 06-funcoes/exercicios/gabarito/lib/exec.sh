#!/usr/bin/env bash
#
# lib/exec.sh - wrapper de execução com logging e dry-run.
#
# Uso: source lib/exec.sh
#      executa rsync -av /origem /destino

# Variável global DRY_RUN (pode ser definida pelo script principal)
DRY_RUN="${DRY_RUN:-0}"

executa() {
    local cmd=("$@")

    if (( DRY_RUN )); then
        log_aviso "[DRY-RUN] ${cmd[*]}"
        return 0
    fi

    log_info "EXEC: ${cmd[*]}"
    "${cmd[@]}"
    local codigo=$?

    if (( codigo == 0 )); then
        log_sucesso "OK (exit 0)"
    else
        log_erro "FALHA (exit $codigo)"
    fi

    return "$codigo"
}

# Teste se executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    DRY_RUN=1
    executa echo "teste dry-run"
    DRY_RUN=0
    executa true
    executa false
fi