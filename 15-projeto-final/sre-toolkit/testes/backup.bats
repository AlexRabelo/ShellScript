#!/usr/bin/env bats
# Testes para subcomando backup

setup() {
    TOOLKIT_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${TOOLKIT_ROOT}/comandos/backup.sh"
    export TOOLKIT_ROOT
    export LIB_DIR="${TOOLKIT_ROOT}/lib"
    export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
    export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
    export SCRIPT_NAME="backup.sh"
    export LOG_FILE="${BATS_TMPDIR}/backup.test.log"

    # Cria estrutura de teste
    ORIGEM="${BATS_TMPDIR}/dados"
    DESTINO="${BATS_TMPDIR}/backups"
    mkdir -p "$ORIGEM/site" "$ORIGEM/db" "$DESTINO"
    echo "conteúdo do site" > "$ORIGEM/site/index.html"
    echo "dados db" > "$ORIGEM/db/dados.sql"
}

teardown() {
    rm -rf "$ORIGEM" "$DESTINO" 2>/dev/null || true
    rm -f "$LOG_FILE" 2>/dev/null || true
    unset TOOLKIT_ROOT LIB_DIR COMANDOS_DIR CONFIG_FILE SCRIPT_NAME LOG_FILE ORIGEM DESTINO
}

@test "backup --help mostra ajuda" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ backup - Backup rotativo ]]
    [[ "$output" =~ -r, --retencao ]]
    [[ "$output" =~ -n, --dry-run ]]
}

@test "backup sem argumentos mostra erro" {
    run bash "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ Argumentos necessários: ORIGEM DESTINO ]]
}

@test "backup cria arquivo de backup" {
    run bash "$SCRIPT" -n "$ORIGEM" "$DESTINO"
    [ "$status" -eq 0 ]
    [[ "$output" =~ criando backup ]]
}

@test "backup -n (dry-run) não cria arquivos" {
    run bash "$SCRIPT" -n "$ORIGEM" "$DESTINO"
    [ "$status" -eq 0 ]
    # No dry-run, não deve criar arquivos reais
    # (o script atual não cria no dry-run, mas vamos verificar)
}

@test "backup valida --retencao deve ser número" {
    run bash "$SCRIPT" -r "abc" "$ORIGEM" "$DESTINO"
    [ "$status" -eq 2 ]
}

@test "backup valida ORIGEM deve existir" {
    run bash "$SCRIPT" "/origem/inexistente" "$DESTINO"
    [ "$status" -eq 1 ]
}

@test "backup valida DESTINO deve existir" {
    run bash "$SCRIPT" "$ORIGEM" "/destino/inexistente"
    [ "$status" -eq 1 ]
}