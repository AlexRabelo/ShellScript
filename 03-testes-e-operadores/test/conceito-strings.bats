#!/usr/bin/env bats
# Testes para conceito-strings.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-strings.sh"
}

@test "conceito-strings.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Vazia ]]
  [[ "$output" =~ Igualdade ]]
  [[ "$output" =~ Glob pattern ]]
  [[ "$output" =~ Regex ]]
  [[ "$output" =~ Comparação lexicográfica ]]
}