#!/usr/bin/env bats
# Testes para analisa-logs.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/analisa-logs.sh"
  TEST_LOG="$BATS_TMPDIR/test.log"
  cat > "$TEST_LOG" << 'EOF'
192.168.1.1 - - [13/Oct/2026:10:00:00 -0300] "GET / HTTP/1.1" 200 1234 0.123
192.168.1.2 - - [13/Oct/2026:10:00:01 -0300] "POST /api HTTP/1.1" 201 567 0.456
192.168.1.1 - - [13/Oct/2026:10:00:02 -0300] "GET /health HTTP/1.1" 200 89 0.023
192.168.1.3 - - [13/Oct/2026:10:00:03 -0300] "GET /admin HTTP/1.1" 403 0 0.001
192.168.1.1 - - [13/Oct/2026:10:00:04 -0300] "GET /api/users HTTP/1.1" 500 0 1.234
EOF
}

@test "analisa-logs.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "analisa-logs.sh sem arquivo falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "analisa-logs.sh -j com log nginx produz JSON válido" {
  run bash "$SCRIPT" -j -f nginx "$TEST_LOG"
  [ "$status" -eq 0 ]
  echo "$output" | jq . >/dev/null
}

@test "analisa-logs.sh -j JSON tem campos esperados" {
  run bash "$SCRIPT" -j -f nginx "$TEST_LOG"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.arquivo' >/dev/null
  echo "$output" | jq -e '.formato' >/dev/null
  echo "$output" | jq -e '.total_linhas' >/dev/null
  echo "$output" | jq -e '.top_ips' >/dev/null
  echo "$output" | jq -e '.status_codes' >/dev/null
}