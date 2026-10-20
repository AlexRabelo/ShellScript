#!/usr/bin/env bats
# Testes para conceito-select.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-select.sh"
}

@test "conceito-select.sh opção 4 sai do menu" {
  run bash -c "echo 4 | bash $SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Menu select ]]
  [[ "$output" =~ Encerrando ]]
}

@test "conceito-select.sh opção 1 executa date" {
  run bash -c "printf '1\n4\n' | bash $SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Encerrando ]]
}