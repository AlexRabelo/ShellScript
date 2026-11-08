#!/usr/bin/env bats
# Testes para aws-inventory.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/aws-inventory.sh"
}

@test "aws-inventory.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "aws-inventory.sh -h mostra ajuda" {
  run bash "$SCRIPT" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "aws-inventory.sh tipo inválido falha" {
  run bash "$SCRIPT" -t invalido
  [ "$status" -eq 2 ]
  [[ "$output" =~ tipo inválido ]]
}

@test "aws-inventory.sh sem AWS CLI falha com código 3" {
  # Testa sem aws/jq no PATH
  run bash -c "PATH=/tmp bash '$SCRIPT' -t ec2"
  [ "$status" -eq 3 ]
  [[ "$output" =~ comando obrigatório ]]
}