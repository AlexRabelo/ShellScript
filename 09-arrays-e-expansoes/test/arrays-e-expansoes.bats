#!/usr/bin/env bats
# Testes para arrays-e-expansoes.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/arrays-e-expansoes.sh"
}

@test "arrays-e-expansoes.sh --help exibe ajuda" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "arrays-e-expansoes.sh rejeita argumento inválido" {
  run bash "$SCRIPT" --invalido
  [ "$status" -eq 2 ]
}

@test "arrays-e-expansoes.sh lista regiões, serviços e expansões" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Regiões configuradas (3)" ]]
  [[ "$output" =~ "nginx -> porta 443" ]]
  [[ "$output" =~ "Arquivo: access.2026.log" ]]
  [[ "$output" =~ "Hífens por underscores: sa_east_1" ]]
}
