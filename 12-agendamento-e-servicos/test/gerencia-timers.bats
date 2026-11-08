#!/usr/bin/env bats
# Testes para gerencia-timers.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/gerencia-timers.sh"
}

@test "gerencia-timers.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ instalar ]]
  [[ "$output" =~ habilitar ]]
  [[ "$output" =~ status ]]
}

@test "gerencia-timers.sh sem comando falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
  [[ "$output" =~ comando obrigatório ]]
}

@test "gerencia-timers.sh comando desconhecido falha" {
  run bash "$SCRIPT" comando-inexistente
  [ "$status" -eq 2 ]
  [[ "$output" =~ comando desconhecido ]]
}