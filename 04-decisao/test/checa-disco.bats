#!/usr/bin/env bats
# Testes para checa-disco.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/checa-disco.sh"
}

@test "checa-disco.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "checa-disco.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}

@test "checa-disco.sh executa e mostra uso do disco" {
  run bash "$SCRIPT"
  [ "$status" -le 2 ]  # 0=OK, 1=AVISO, 2=CRÍTICO
  [[ "$output" =~ Disco em ]] || [[ "$output" =~ uso do disco ]]
}