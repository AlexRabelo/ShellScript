#!/usr/bin/env bats
# Testes para espera-servico.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/espera-servico.sh"
}

@test "espera-servico.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "espera-servico.sh sem argumentos falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "espera-servico.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n localhost 80
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}

@test "espera-servico.sh com porta inválida falha" {
  run bash "$SCRIPT" -n localhost 99999
  [ "$status" -eq 2 ]
  [[ "$output" =~ Porta inválida ]]
}