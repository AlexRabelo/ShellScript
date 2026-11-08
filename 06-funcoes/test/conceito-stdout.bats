#!/usr/bin/env bats
# Testes para conceito-stdout.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-stdout.sh"
}

@test "conceito-stdout.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Retorno via stdout ]]
  [[ "$output" =~ Dobro de 7: 14 ]]
  [[ "$output" =~ Triplo do dobro de 5: 30 ]]
  [[ "$output" =~ Pares até 10 ]]
}