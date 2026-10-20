#!/usr/bin/env bats
# Testes para processa-inventario.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/processa-inventario.sh"
  TEST_CSV="$BATS_TMPDIR/inventario.csv"
}

teardown() {
  rm -f "$TEST_CSV" 2>/dev/null || true
}

@test "processa-inventario.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "processa-inventario.sh -n dry-run processa CSV" {
  run bash "$SCRIPT" -n "$TEST_CSV"
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [[ "$output" =~ Processamento de Inventário ]]
  [[ "$output" =~ web01 ]]
  [[ "$output" =~ Produção ]]
}