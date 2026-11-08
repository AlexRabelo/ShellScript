#!/usr/bin/env bats
# Testes para testa-arquivo.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/testa-arquivo.sh"
  TEST_FILE="$BATS_TMPDIR/teste.txt"
  echo "conteúdo" > "$TEST_FILE"
}

@test "testa-arquivo.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "testa-arquivo.sh sem argumentos falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "testa-arquivo.sh com arquivo regular mostra testes positivos" {
  run bash "$SCRIPT" "$TEST_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Existe ]]
  [[ "$output" =~ Arquivo regular ]]
  [[ "$output" =~ Legível ]]
  [[ "$output" =~ Gravável ]]
  [[ "$output" =~ Não vazio ]]
}