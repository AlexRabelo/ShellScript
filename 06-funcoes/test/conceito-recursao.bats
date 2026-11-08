#!/usr/bin/env bats
# Testes para conceito-recursao.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-recursao.sh"
}

@test "conceito-recursao.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Fatorial recursivo ]]
  [[ "$output" =~ Fibonacci recursivo ]]
  [[ "$output" =~ 5! = 120 ]]
  [[ "$output" =~ fib(6) = 8 ]]
}