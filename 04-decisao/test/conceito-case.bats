#!/usr/bin/env bats
# Testes para conceito-case.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-case.sh"
}

@test "conceito-case.sh sem argumentos usa defaults" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Ação: STATUS ]]
  [[ "$output" =~ Nível: NORMAL ]]
  [[ "$output" =~ Tipo desconhecido ]]
}

@test "conceito-case.sh start info app.sh" {
  run bash "$SCRIPT" start info app.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ Ação: INICIAR ]]
  [[ "$output" =~ Nível: NORMAL ]]
  [[ "$output" =~ Script SHELL ]]
}

@test "conceito-case.sh stop error teste.log" {
  run bash "$SCRIPT" stop error teste.log
  [ "$status" -eq 0 ]
  [[ "$output" =~ Ação: PARAR ]]
  [[ "$output" =~ Nível: CRÍTICO ]]
  [[ "$output" =~ Arquivo de LOG ]]
}