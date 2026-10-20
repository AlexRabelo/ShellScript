#!/usr/bin/env bats
# Testes para backup-simples.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/backup-simples.sh"
  TEST_FILE="$BATS_TMPDIR/origem.txt"
  TEST_DEST="$BATS_TMPDIR/backups"
  echo "conteúdo de teste" > "$TEST_FILE"
}

teardown() {
  rm -rf "$TEST_DEST" 2>/dev/null || true
}

@test "backup-simples.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ backup-simples.sh ]]
}

@test "backup-simples.sh sem argumentos falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "backup-simples.sh -n dry-run não cria arquivo" {
  run bash "$SCRIPT" -n "$TEST_FILE" "$TEST_DEST"
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [ ! -d "$TEST_DEST" ]
}

@test "backup-simples.sh cria backup com data no nome" {
  run bash "$SCRIPT" "$TEST_FILE" "$TEST_DEST"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Backup criado: ]]
  [ -d "$TEST_DEST" ]
  # Verifica que existe pelo menos um arquivo backup
  count=$(find "$TEST_DEST" -name "origem-*" -type f | wc -l)
  [ "$count" -ge 1 ]
}