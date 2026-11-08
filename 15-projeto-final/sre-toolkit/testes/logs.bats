#!/usr/bin/env bats
# Testes para subcomando logs

setup() {
    TOOLKIT_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${TOOLKIT_ROOT}/comandos/logs.sh"
    export TOOLKIT_ROOT
    export LIB_DIR="${TOOLKIT_ROOT}/lib"
    export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
    export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
    export SCRIPT_NAME="logs.sh"
    export LOG_FILE="${BATS_TMPDIR}/logs.test.log"

    # Cria logs de teste
    NGINX_LOG="${BATS_TMPDIR}/test-nginx.log"
    cat > "$NGINX_LOG" << 'EOF'
192.168.1.1 - - [15/Oct/2026:10:00:00 +0000] "GET / HTTP/1.1" 200 612
192.168.1.2 - - [15/Oct/2026:10:00:01 +0000] "POST /api HTTP/1.1" 200 345
192.168.1.1 - - [15/Oct/2026:10:00:02 +0000] "GET /dashboard HTTP/1.1" 200 1234
EOF

    JSON_LOG="${BATS_TMPDIR}/test-json.log"
    cat > "$JSON_LOG" << 'EOF'
{"timestamp":"2026-10-15T10:00:00Z","level":"INFO","msg":"User login","user_id":123}
{"timestamp":"2026-10-15T10:00:01Z","level":"ERROR","msg":"DB connection failed","error":"timeout"}
{"timestamp":"2026-10-15T10:00:02Z","level":"INFO","msg":"Retry successful","user_id":123}
EOF
}

teardown() {
    rm -f "$NGINX_LOG" "$JSON_LOG" "$LOG_FILE" 2>/dev/null || true
    unset TOOLKIT_ROOT LIB_DIR COMANDOS_DIR CONFIG_FILE SCRIPT_NAME LOG_FILE NGINX_LOG JSON_LOG
}

@test "logs --help mostra ajuda" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ logs - Análise de logs ]]
    [[ "$output" =~ -f, --formato ]]
    [[ "$output" =~ -l, --limite ]]
}

@test "logs sem argumentos mostra erro" {
    run bash "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" =~ Arquivo de log obrigatório ]]
}

@test "logs -f nginx -j produz JSON válido" {
    run bash "$SCRIPT" -j -f nginx "$NGINX_LOG"
    [ "$status" -eq 0 ]
    echo "$output" | jq . >/dev/null
}

@test "logs -f json -j produz JSON válido" {
    run bash "$SCRIPT" -j -f json "$JSON_LOG"
    [ "$status" -eq 0 ]
    echo "$output" | jq . >/dev/null
}

@test "logs JSON tem campos esperados" {
    run bash "$SCRIPT" -j -f nginx "$NGINX_LOG"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.timestamp' >/dev/null
    echo "$output" | jq -e '.analises' >/dev/null
    echo "$output" | jq -e '.analises[0].arquivo' >/dev/null
    echo "$output" | jq -e '.analises[0].linhas' >/dev/null
}

@test "logs valida arquivo deve existir" {
    run bash "$SCRIPT" "/arquivo/inexistente.log"
    [ "$status" -eq 2 ] || [ "$status" -eq 1 ]
}