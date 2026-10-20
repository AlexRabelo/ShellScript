#!/usr/bin/env bats
# Testes para info-servidor.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/info-servidor.sh"
}

@test "info-servidor.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ info-servidor.sh ]]
}

@test "info-servidor.sh executa e mostra informações do sistema" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Informações do Sistema ]]
  [[ "$output" =~ Hostname: ]]
  [[ "$output" =~ Uptime: ]]
  [[ "$output" =~ Kernel: ]]
  [[ "$output" =~ Distribuicao: ]]
}

@test "info-servidor.sh -n dry-run não falha" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
}