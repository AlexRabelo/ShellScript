#!/usr/bin/env bats
# Testes para conceito-variaveis.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-variaveis.sh"
}

@test "conceito-variaveis.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Atribuição e leitura básica ]]
  [[ "$output" =~ nome=servidor-web ]]
  [[ "$output" =~ porta=443 ]]
  [[ "$output" =~ Expansão com default ]]
  [[ "$output" =~ Expansão com atribuição ]]
  [[ "$output" =~ Expansão condicional ]]
  [[ "$output" =~ Tamanho da string ]]
}