#!/usr/bin/env bats
# Testes para conceito-ifs-mapfile.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-ifs-mapfile.sh"
}

@test "conceito-ifs-mapfile.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ IFS customizado ]]
  [[ "$output" =~ mapfile ]]
  [[ "$output" =~ linha 1 ]]
}