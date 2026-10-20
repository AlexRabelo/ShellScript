#!/usr/bin/env bats
# Testes para conceito-parametros.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-parametros.sh"
}

@test "conceito-parametros.sh com argumentos mostra parâmetros" {
  run bash "$SCRIPT" arg1 arg2 arg3
  [ "$status" -eq 0 ]
  [[ "$output" =~ Parâmetros recebidos ]]
  [[ "$output" =~ Quantidade.*3 ]]
  [[ "$output" =~ arg1 ]]
  [[ "$output" =~ arg2 ]]
  [[ "$output" =~ arg3 ]]
}

@test "conceito-parametros.sh sem argumentos mostra zeros" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Quantidade.*0 ]]
}