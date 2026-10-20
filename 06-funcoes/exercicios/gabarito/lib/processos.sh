#!/usr/bin/env bash
#
# lib/processos.sh - funções para gerenciar processos por usuário.
#
# Uso: source lib/processos.sh
#      lista_processos_por_usuario "www-data"
#      mata_processos_por_usuario "www-data" SIGTERM

# Lista PIDs dos processos de um usuário (retorna array via stdout)
lista_processos_por_usuario() {
    local usuario="$1"
    local pids

    # pgrep -u retorna PIDs, um por linha
    mapfile -t pids < <(pgrep -u "$usuario" 2>/dev/null || true)

    if (( ${#pids[@]} > 0 )); then
        printf '%s\n' "${pids[@]}"
        return 0
    else
        return 1
    fi
}

# Mata processos de um usuário com escalonamento de sinal
mata_processos_por_usuario() {
    local usuario="$1"
    local sinal="${2:-SIGTERM}"

    local pids
    mapfile -t pids < <(pgrep -u "$usuario" 2>/dev/null || true)

    if (( ${#pids[@]} == 0 )); then
        echo "Nenhum processo encontrado para usuário: $usuario"
        return 0
    fi

    echo "Enviando $sinal para ${#pids[@]} processo(s) do usuário $usuario..."
    kill -s "$sinal" "${pids[@]}" 2>/dev/null

    # Aguarda até 5s para término gracioso
    if [[ "$sinal" == "SIGTERM" ]]; then
        sleep 5
        # Verifica se restaram
        mapfile -t pids < <(pgrep -u "$usuario" 2>/dev/null || true)
        if (( ${#pids[@]} > 0 )); then
            echo "${#pids[@]} processo(s) persistiram. Enviando SIGKILL..."
            kill -s SIGKILL "${pids[@]}" 2>/dev/null
            sleep 1
        fi
    fi

    mapfile -t pids < <(pgrep -u "$usuario" 2>/dev/null || true)
    if (( ${#pids[@]} == 0 )); then
        echo "Todos os processos finalizados."
        return 0
    else
        echo "Ainda restam ${#pids[@]} processo(s)." >&2
        return 1
    fi
}

# Teste se executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    lista_processos_por_usuario "$(whoami)"
fi