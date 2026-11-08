#!/usr/bin/env bash
#
# script-corrigido.sh - Versão corrigida sem avisos do ShellCheck
#
# Correções aplicadas:
# - SC2045: não usar ls em loop (usar glob)
# - SC2086: aspas em expansões ($arquivos -> "$arquivos")
# - SC2002: cat desnecessário (wc -l < arquivo)
# - SC2162: read sem -r
# - SC2155: declaração e atribuição separadas
# - SC2034: variável não usada
# - SC2120: função sem parâmetros declarados

set -Eeuo pipefail

processar_logs() {
    local dir_logs="/var/log"
    local padrao="*.log"

    # SC2045: usar glob em vez de ls
    # SC2086: aspas na expansão do array
    local arquivos=()
    for arq in "$dir_logs"/$padrao; do
        [[ -f "$arq" ]] && arquivos+=("$arq")
    done

    if [[ ${#arquivos[@]} -eq 0 ]]; then
        echo "Nenhum arquivo .log encontrado em $dir_logs" >&2
        return 0
    fi

    for arq in "${arquivos[@]}"; do
        # SC2002: wc -l < arquivo em vez de cat | wc -l
        local linhas
        linhas=$(wc -l < "$arq")
        echo "Arquivo: $arq, Linhas: $linhas"

        # SC2154: $linhas definido no loop, mas usado fora - mover para dentro
        if [[ "$linhas" -gt 1000 ]]; then
            echo "  -> Arquivo grande detectado: $arq ($linhas linhas)"
        fi
    done
}

# SC2120: funcao() referencia $1 mas não declara parâmetros
# Correção: declarar parâmetro explicitamente
exibir_mensagem() {
    local mensagem="$1"
    echo "$mensagem"
}

main() {
    processar_logs
    exibir_mensagem "teste"
}

main "$@"