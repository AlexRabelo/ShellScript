#!/usr/bin/env bats
# Testes para valida-entrada.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/valida-entrada.sh"
}

@test "valida-entrada.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "valida-entrada.sh -n dry-run executa sem pedir input" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}