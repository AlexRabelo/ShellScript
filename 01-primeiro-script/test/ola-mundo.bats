#!/usr/bin/env bats
# Testes para ola-mundo.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/ola-mundo.sh"
}

@test "ola-mundo.sh executa e mostra saudação" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Olá, mundo! ]]
  [[ "$output" =~ primeiro shell script ]]
}