#!/usr/bin/env bats
# Testes para conceito-expansoes.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-expansoes.sh"
}

@test "conceito-expansoes.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Path manipulation ]]
  [[ "$output" =~ Substituição ]]
  [[ "$output" =~ Case ]]
  [[ "$output" =~ Substring ]]
  [[ "$output" =~ Comprimento ]]
}