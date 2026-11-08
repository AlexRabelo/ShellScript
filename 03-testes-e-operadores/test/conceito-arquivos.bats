#!/usr/bin/env bats
# Testes para conceito-arquivos.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-arquivos.sh"
}

@test "conceito-arquivos.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Existência e tipo ]]
  [[ "$output" =~ Permissões ]]
  [[ "$output" =~ Tamanho e tempo ]]
}