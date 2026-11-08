#!/usr/bin/env bats
# Testes para conceito-funcoes.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-funcoes.sh"
}

@test "conceito-funcoes.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Definição e chamada ]]
  [[ "$output" =~ Argumentos ]]
  [[ "$output" =~ Retorno de status ]]
  [[ "$output" =~ Return explícito ]]
  [[ "$output" =~ Escopo: local vs global ]]
}