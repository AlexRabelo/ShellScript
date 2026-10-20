#!/usr/bin/env bats
# Testes para conceito-if.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-if.sh"
}

@test "conceito-if.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ if simples ]]
  [[ "$output" =~ if / else ]]
  [[ "$output" =~ if / elif / else ]]
  [[ "$output" =~ Comando direto no if ]]
}