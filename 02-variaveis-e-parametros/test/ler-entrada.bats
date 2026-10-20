#!/usr/bin/env bats
# Testes para ler-entrada.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/ler-entrada.sh"
}

@test "ler-entrada.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ ler-entrada.sh ]]
}

@test "ler-entrada.sh -n dry-run executa sem pedir input" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [[ "$output" =~ Digite seu nome ]]
  [[ "$output" =~ Digite uma senha ]]
  [[ "$output" =~ Digite dois números ]]
}