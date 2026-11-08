#!/usr/bin/env bats
# Testes para healthcheck-http.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/healthcheck-http.sh"
}

@test "healthcheck-http.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "healthcheck-http.sh sem URL falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
  [[ "$output" =~ obrigatória ]]
}

@test "healthcheck-http.sh -n dry-run falha (requer URL real para testar)" {
  run bash "$SCRIPT" -n -j https://httpbin.org/get
  [ "$status" -eq 0 ]
  echo "$output" | jq . >/dev/null
}