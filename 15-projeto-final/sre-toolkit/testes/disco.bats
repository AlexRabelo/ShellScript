#!/usr/bin/env bats
# Testes para subcomando disco

setup() {
    TOOLKIT_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${TOOLKIT_ROOT}/comandos/disco.sh"
    export TOOLKIT_ROOT
    export LIB_DIR="${TOOLKIT_ROOT}/lib"
    export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
    export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
    export SCRIPT_NAME="disco.sh"
    export LOG_FILE="${BATS_TMPDIR}/disco.test.log"

    # Cria diretório de teste com arquivos de idades diferentes
    TEST_DIR="${BATS_TMPDIR}/teste-disco"
    mkdir -p "$TEST_DIR"
    echo "recente" > "$TEST_DIR/recent.log"
    touch -d "40 days ago" "$TEST_DIR/old.log"
    touch -d "10 days ago" "$TEST_DIR/medium.log"
}

teardown() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
    rm -f "$LOG_FILE" 2>/dev/null || true
    unset TOOLKIT_ROOT LIB_DIR COMANDOS_DIR CONFIG_FILE SCRIPT_NAME LOG_FILE TEST_DIR
}

@test "disco --help mostra ajuda" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ disco - Análise e limpeza ]]
    [[ "$output" =~ --limpeza ]]
    [[ "$output" =~ --dias ]]
    [[ "$output" =~ --dir ]]
}

@test "disco -j produz JSON válido" {
    run bash "$SCRIPT" -j --dir "$TEST_DIR" --dias 30
    [ "$status" -eq 0 ]
    echo "$output" | jq . >/dev/null
}

@test "disco -j JSON tem campos esperados" {
    run bash "$SCRIPT" -j --dir "$TEST_DIR" --dias 30
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.diretorio' >/dev/null
    echo "$output" | jq -e '.dias_limite' >/dev/null
    echo "$output" | jq -e '.total_arquivos' >/dev/null
    echo "$output" | jq -e '.arquivos_mais_antigos' >/dev/null
    echo "$output" | jq -e '.detalhes' >/dev/null
}

@test "disco identifica arquivos antigos (--dias 30)" {
    run bash "$SCRIPT" -j --dir "$TEST_DIR" --dias 30
    [ "$status" -eq 0 ]
    local antigos
    antigos=$(echo "$output" | jq -r '.arquivos_mais_antigos')
    [ "$antigos" -eq 1 ]  # Apenas old.log tem 40 dias
}

@test "disco --limpeza remove arquivos antigos" {
    run bash "$SCRIPT" -j --dir "$TEST_DIR" --dias 30 --limpeza
    [ "$status" -eq 0 ]
    local removidos
    removidos=$(echo "$output" | jq -r '.limpeza.arquivos_removidos')
    [ "$removidos" -eq 1 ]
    # Verifica que old.log foi removido
    [ ! -f "$TEST_DIR/old.log" ]
    # Verifica que recent.log e medium.log permanecem
    [ -f "$TEST_DIR/recent.log" ]
    [ -f "$TEST_DIR/medium.log" ]
}

@test "disco -n (dry-run) não remove arquivos" {
    run bash "$SCRIPT" -n -j --dir "$TEST_DIR" --dias 30 --limpeza
    [ "$status" -eq 0 ]
    local removidos
    removidos=$(echo "$output" | jq -r '.limpeza.arquivos_removidos // 0')
    [ "$removidos" -eq 0 ]
    # Arquivo ainda deve existir
    [ -f "$TEST_DIR/old.log" ]
}

@test "disco valida --dias deve ser número" {
    run bash "$SCRIPT" --dir "$TEST_DIR" --dias "abc"
    [ "$status" -eq 2 ]
    [[ "$output" =~ número ]]
}

@test "disco valida --dir deve existir" {
    run bash "$SCRIPT" --dir "/diretorio/inexistente" --dias 30
    [ "$status" -eq 1 ]
}