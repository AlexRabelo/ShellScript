#!/usr/bin/env bats
# Testes para subcomando health

setup() {
    TOOLKIT_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${TOOLKIT_ROOT}/comandos/health.sh"
    export TOOLKIT_ROOT
    export LIB_DIR="${TOOLKIT_ROOT}/lib"
    export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
    export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
    export SCRIPT_NAME="health.sh"
    export LOG_FILE="${BATS_TMPDIR}/health.test.log"

    # Cria arquivos de configuração de teste
    SERVICOS_FILE="${BATS_TMPDIR}/servicos.txt"
    ENDPOINTS_FILE="${BATS_TMPDIR}/endpoints.txt"
    echo -e "sshd\nsystemd-journald" > "$SERVICOS_FILE"
    echo -e "https://httpbin.org/status/200\nhttps://httpbin.org/status/500" > "$ENDPOINTS_FILE"
}

teardown() {
    rm -f "$SERVICOS_FILE" "$ENDPOINTS_FILE" "$LOG_FILE" 2>/dev/null || true
    unset TOOLKIT_ROOT LIB_DIR COMANDOS_DIR CONFIG_FILE SCRIPT_NAME LOG_FILE SERVICOS_FILE ENDPOINTS_FILE
}

@test "health --help mostra ajuda" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ health - Healthcheck ]]
    [[ "$output" =~ -j, --json ]]
    [[ "$output" =~ -t, --timeout ]]
    [[ "$output" =~ -s, --servicos ]]
    [[ "$output" =~ -e, --endpoints ]]
}

@test "health sem argumentos mostra erro" {
    run bash "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ Opção desconhecida ]] || [[ "$output" =~ Argumentos necessários ]]
}

@test "health -j com serviços produz JSON válido" {
    run bash "$SCRIPT" -j -s "$SERVICOS_FILE"
    [ "$status" -eq 0 ]
    echo "$output" | jq . >/dev/null
}

@test "health JSON tem campos esperados" {
    run bash "$SCRIPT" -j -s "$SERVICOS_FILE" -e "$ENDPOINTS_FILE"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.timestamp' >/dev/null
    echo "$output" | jq -e '.total' >/dev/null
    echo "$output" | jq -e '.ok' >/dev/null
    echo "$output" | jq -e '.fail' >/dev/null
    echo "$output" | jq -e '.verificacoes' >/dev/null
}

@test "health valida --timeout deve ser número" {
    run bash "$SCRIPT" -t "abc" -s "$SERVICOS_FILE"
    [ "$status" -eq 2 ]
}

@test "health -j verifica estrutura de verificacoes" {
    run bash "$SCRIPT" -j -s "$SERVICOS_FILE" -e "$ENDPOINTS_FILE"
    [ "$status" -eq 0 ]
    local tipo
    tipo=$(echo "$output" | jq -r '.verificacoes[0].tipo')
    [[ "$tipo" == "systemd" || "$tipo" == "http ]]
}