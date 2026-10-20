#!/usr/bin/env bats
# Testes para conceito-getopts.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-getopts.sh"
}

@test "conceito-getopts.sh -h mostra ajuda" {
  run bash "$SCRIPT" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "conceito-getopts.sh --help mostra ajuda" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "conceito-getopts.sh -v -n -f input.txt -o output.txt" {
  run bash "$SCRIPT" -v -n -f input.txt -o output.txt arg1 arg2
  [ "$status" -eq 0 ]
  [[ "$output" =~ VERBOSE=1 ]]
  [[ "$output" =~ DRY_RUN=1 ]]
  [[ "$output" =~ ARQUIVO=input.txt ]]
  [[ "$output" =~ OUTPUT=output.txt ]]
  [[ "$output" =~ Args restantes: arg1 arg2 ]]
}

@test "conceito-getopts.sh --verbose --dry-run --file=input --output=output" {
  run bash "$SCRIPT" --verbose --dry-run --file=input --output=output
  [ "$status" -eq 0 ]
  [[ "$output" =~ VERBOSE=1 ]]
  [[ "$output" =~ DRY_RUN=1 ]]
  [[ "$output" =~ ARQUIVO=input ]]
  [[ "$output" =~ OUTPUT=output ]]
}