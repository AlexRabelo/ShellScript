#!/usr/bin/env bats
# Testes para codigos-de-saida.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/codigos-de-saida.sh"
}

@test "codigos-de-saida.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ codigos-de-saida.sh ]]
}

@test "codigos-de-saida.sh sucesso retorna código 0" {
  run bash "$SCRIPT" sucesso
  [ "$status" -eq 0 ]
  [[ "$output" =~ sucesso ]]
}

@test "codigos-de-saida.sh falha retorna código 1" {
  run bash "$SCRIPT" falha
  [ "$status" -eq 1 ]
  [[ "$output" =~ errado ]]
}

@test "codigos-de-saida.sh uso retorna código 2" {
  run bash "$SCRIPT" uso
  [ "$status" -eq 2 ]
}

@test "codigos-de-saida.sh argumento inválido retorna código 2" {
  run bash "$SCRIPT" invalido
  [ "$status" -eq 2 ]
}