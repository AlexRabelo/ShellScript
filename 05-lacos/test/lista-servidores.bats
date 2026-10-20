#!/usr/bin/env bats
# Testes para lista-servidores.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/lista-servidores.sh"
  TEST_HOSTS="$BATS_TMPDIR/hosts.txt"
  echo "8.8.8.8" > "$TEST_HOSTS"
  echo "1.1.1.1" >> "$TEST_HOSTS"
}

@test "lista-servidores.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "lista-servidores.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n "$TEST_HOSTS"
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [[ "$output" =~ Testando ]]
}