#!/usr/bin/env bats
# Testes para detecta-distro.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/detecta-distro.sh"
}

@test "detecta-distro.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "detecta-distro.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}

@test "detecta-distro.sh executa e detecta distribuição" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Distribuição detectada ]]
  [[ "$output" =~ Gerenciador de pacotes ]]
}