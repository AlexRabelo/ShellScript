#!/usr/bin/env bats
# Testes para sre-toolkit (script principal)

setup() {
    TOOLKIT_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${TOOLKIT_ROOT}/bin/sre-toolkit"
    export TOOLKIT_ROOT
    export LIB_DIR="${TOOLKIT_ROOT}/lib"
    export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
    export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
}

teardown() {
    unset TOOLKIT_ROOT LIB_DIR COMANDOS_DIR CONFIG_FILE
}

@test "sre-toolkit --help mostra ajuda principal" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ sre-toolkit - Toolkit SRE ]]
    [[ "$output" =~ Subcomandos disponíveis: ]]
    [[ "$output" =~ saude ]]
    [[ "$output" =~ disco ]]
    [[ "$output" =~ backup ]]
    [[ "$output" =~ health ]]
    [[ "$output" =~ logs ]]
    [[ "$output" =~ aws ]]
    [[ "$output" =~ incidente ]]
}

@test "sre-toolkit sem argumentos mostra erro" {
    run bash "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ Subcomando obrigatório ]]
}

@test "sre-toolkit subcomando inexistente mostra erro" {
    run bash "$SCRIPT" nao-existe
    [ "$status" -eq 2 ]
    [[ "$output" =~ Subcomando inválido: nao-existe ]]
}

@test "sre-toolkit --help sem subcomando mostra ajuda principal" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ Uso: sre-toolkit <subcomando> ]]
}

@test "sre-toolkit -v define VERBOSE=1" {
    run bash "$SCRIPT" -v saude --help
    [ "$status" -eq 0 ]
}

@test "sre-toolkit -n define DRY_RUN=1" {
    run bash "$SCRIPT" -n saude --help
    [ "$status" -eq 0 ]
}

@test "sre-toolkit -c config file carrega configuração" {
    # Cria config temporária
    local tmp_config="${BATS_TMPDIR}/test.conf"
    echo 'TEST_VAR="valor-teste"' > "$tmp_config"

    run bash "$SCRIPT" -c "$tmp_config" saude --help
    [ "$status" -eq 0 ]

    rm -f "$tmp_config"
}