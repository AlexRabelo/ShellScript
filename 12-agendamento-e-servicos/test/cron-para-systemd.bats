#!/usr/bin/env bats
# Testes para cron-para-systemd.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/cron-para-systemd.sh"
}

@test "cron-para-systemd.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "cron-para-systemd.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [[ "$output" =~ MIGRAÇÃO CRON ]]
  [[ "$output" =~ CRON TRADICIONAL ]]
  [[ "$output" =~ SYSTEMD TIMERS ]]
  [[ "$output" =~ VANTAGENS ]]
  [[ "$output" =~ BOAS PRÁTICAS ]]
}