#!/usr/bin/env bats
# Testes para valida-requisitos.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/valida-requisitos.sh"
}

@test "valida-requisitos.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "valida-requisitos.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}

@test "valida-requisitos.sh executa e valida pré-requisitos" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Verificação de pré-requisitos ]]
  [[ "$output" =~ comandos necessários ]]
}