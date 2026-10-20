#!/usr/bin/env bats
# Testes para subcomando saude

setup() {
    TOOLKIT_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${TOOLKIT_ROOT}/comandos/saude.sh"
    export TOOLKIT_ROOT
    export LIB_DIR="${TOOLKIT_ROOT}/lib"
    export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
    export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
    export SCRIPT_NAME="saude.sh"
    export LOG_FILE="${BATS_TMPDIR}/saude.test.log"
}

teardown() {
    rm -f "$LOG_FILE" 2>/dev/null || true
    unset TOOLKIT_ROOT LIB_DIR COMANDOS_DIR CONFIG_FILE SCRIPT_NAME LOG_FILE
}

@test "saude --help mostra ajuda" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ saude - Relatório de saúde ]]
    [[ "$output" =~ -j, --json ]]
    [[ "$output" =~ -v, --verbose ]]
}

@test "saude -j produz JSON válido" {
    run bash "$SCRIPT" -j
    [ "$status" -eq 0 ]
    echo "$output" | jq . >/dev/null
}

@test "saude -j JSON tem campos esperados" {
    run bash "$SCRIPT" -j
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.timestamp' >/dev/null
    echo "$output" | jq -e '.sistema.hostname' >/dev/null
    echo "$output" | jq -e '.cpu.uso_percentual' >/dev/null
    echo "$output" | jq -e '.memoria.uso_percentual' >/dev/null
    echo "$output" | jq -e '.disco' >/dev/null
    echo "$output" | jq -e '.processos.total' >/dev/null
}

@test "saude sem argumentos produz saída texto" {
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ SAÚDE DO SERVIDOR ]]
    [[ "$output" =~ Hostname: ]]
    [[ "$output" =~ CPU: ]]
    [[ "$output" =~ RAM: ]]
    [[ "$output" =~ DISCO: ]]
    [[ "$output" =~ Processos: ]]
}

@test "saude -v executa sem erro" {
    run bash "$SCRIPT" -v
    [ "$status" -eq 0 ]
}