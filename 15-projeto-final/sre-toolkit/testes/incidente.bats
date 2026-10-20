#!/usr/bin/env bats
# Testes para subcomando incidente

setup() {
    TOOLKIT_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${TOOLKIT_ROOT}/comandos/incidente.sh"
    export TOOLKIT_ROOT
    export LIB_DIR="${TOOLKIT_ROOT}/lib"
    export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
    export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
    export SCRIPT_NAME="incidente.sh"
    export LOG_FILE="${BATS_TMPDIR}/incidente.test.log"
}

teardown() {
    rm -rf /tmp/incidente-test-* 2>/dev/null || true
    rm -f "$LOG_FILE" 2>/dev/null || true
    unset TOOLKIT_ROOT LIB_DIR COMANDOS_DIR CONFIG_FILE SCRIPT_NAME LOG_FILE
}

@test "incidente --help mostra ajuda" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ incidente - Coleta de diagnóstico ]]
    [[ "$output" =~ --coleta-completa ]]
    [[ "$output" =~ --dir ]]
}

@test "incidente -j produz JSON válido" {
    run bash "$SCRIPT" -j --dir "${BATS_TMPDIR}/incidente-test-1"
    [ "$status" -eq 0 ]
    echo "$output" | jq . >/dev/null
}

@test "incidente JSON tem campos esperados" {
    run bash "$SCRIPT" -j --dir "${BATS_TMPDIR}/incidente-test-2"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.diretorio' >/dev/null
    echo "$output" | jq -e '.coleta_completa' >/dev/null
    echo "$output" | jq -e '.timestamp' >/dev/null
    echo "$output" | jq -e '.mensagem' >/dev/null
}

@test "incidente --coleta-completa cria mais arquivos" {
    run bash "$SCRIPT" --dir "${BATS_TMPDIR}/incidente-test-3" --coleta-completa
    [ "$status" -eq 0 ]
    local dir="${BATS_TMPDIR}/incidente-test-3"
    [ -f "$dir/system_info.txt" ]
    [ -f "$dir/os_info.txt" ]
    [ -f "$dir/top.txt" ]
    [ -f "$dir/pci_info.txt" ]  # Coleta completa inclui hardware
}

@test "incidente básica cria arquivos essenciais" {
    run bash "$SCRIPT" --dir "${BATS_TMPDIR}/incidente-test-4"
    [ "$status" -eq 0 ]
    local dir="${BATS_TMPDIR}/incidente-test-4"
    [ -f "$dir/system_info.txt" ]
    [ -f "$dir/os_info.txt" ]
    [ -f "$dir/top.txt" ]
    [ -f "$dir/top_cpu.txt" ]
    [ -f "$dir/top_mem.txt" ]
    [ -f "$dir/disk_usage.txt" ]
    [ -f "$dir/memory_usage.txt" ]
    [ -f "$dir/network_ports.txt" ]
    [ -f "$dir/services_running.txt" ]
    [ -f "$dir/services_failed.txt" ]
    [ -f "$dir/journald_recent.txt" ]
}