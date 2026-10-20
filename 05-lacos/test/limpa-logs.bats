#!/usr/bin/env bats
# Testes para limpa-logs.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/limpa-logs.sh"
  TEST_DIR="$BATS_TMPDIR/logs"
  mkdir -p "$TEST_DIR"
  echo "log antigo" > "$TEST_DIR/antigo.log"
  touch -d "10 days ago" "$TEST_DIR/antigo.log"
  echo "log recente" > "$TEST_DIR/recent.log"
  touch -d "1 day ago" "$TEST_DIR/recent.log"
}

teardown() {
  rm -rf "$TEST_DIR" 2>/dev/null || true
}

@test "limpa-logs.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "limpa-logs.sh -n dry-run lista arquivos antigos" {
  run bash "$SCRIPT" -n "$TEST_DIR" 7
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [[ "$output" =~ antigo.log ]]
  [[ ! "$output" =~ recent.log ]]
}

@test "limpa-logs.sh com diretório inexistente falha" {
  run bash "$SCRIPT" -n "/diretorio/inexistente" 7
  [ "$status" -eq 1 ]
  [[ "$output" =~ não existe ]]
}