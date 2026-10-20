#!/usr/bin/env bats
# Testes para conceito-arrays.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-arrays.sh"
}

@test "conceito-arrays.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Array indexado ]]
  [[ "$output" =~ Array associativo ]]
  [[ "$output" =~ declare -p ]]
}