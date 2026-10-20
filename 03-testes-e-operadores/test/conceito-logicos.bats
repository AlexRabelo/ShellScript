#!/usr/bin/env bats
# Testes para conceito-logicos.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-logicos.sh"
}

@test "conceito-logicos.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ E.*&& ]]
  [[ "$output" =~ OU.*|| ]]
  [[ "$output" =~ NÃO.*! ]]
  [[ "$output" =~ Precedência ]]
}