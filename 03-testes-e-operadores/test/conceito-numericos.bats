#!/usr/bin/env bats
# Testes para conceito-numericos.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-numericos.sh"
}

@test "conceito-numericos.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Preferido ]]
  [[ "$output" =~ Alternativo ]]
  [[ "$output" =~ Aritmética ]]
}