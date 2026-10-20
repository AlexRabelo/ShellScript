#!/usr/bin/env bats
# Testes para funcoes-basicas.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/funcoes-basicas.sh"
}

@test "funcoes-basicas.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "funcoes-basicas.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}

@test "funcoes-basicas.sh executa e demonstra funções" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ 2 é par ]]
  [[ "$output" =~ 3 é ímpar ]]
  [[ "$output" =~ Dobro de 7: 14 ]]
  [[ "$output" =~ Dobro de 15: 30 ]]
  [[ "$output" =~ Positivo ]]
  [[ "$output" =~ Negativo ]]
  [[ "$output" =~ Zero ]]
  [[ "$output" =~ variável local não vazou ]]
}