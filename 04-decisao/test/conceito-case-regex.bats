#!/usr/bin/env bats
# Testes para conceito-case-regex.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-case-regex.sh"
}

@test "conceito-case-regex.sh sem argumentos usa Sim" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Detectou 'sim' ]]
  [[ "$output" =~ sim (nocasematch) ]]
}

@test "conceito-case-regex.sh não" {
  run bash "$SCRIPT" não
  [ "$status" -eq 0 ]
  [[ "$output" =~ Detectou 'não' ]]
  [[ "$output" =~ não (nocasematch) ]]
}

@test "conceito-case-regex.sh YES" {
  run bash "$SCRIPT" YES
  [ "$status" -eq 0 ]
  [[ "$output" =~ Detectou 'yes' ]]
  [[ "$output" =~ yes/y (nocasematch) ]]
}