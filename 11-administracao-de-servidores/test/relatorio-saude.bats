#!/usr/bin/env bats
# Testes para relatorio-saude.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/relatorio-saude.sh"
}

@test "relatorio-saude.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "relatorio-saude.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}

@test "relatorio-saude.sh -j produz JSON válido" {
  run bash "$SCRIPT" -j
  [ "$status" -eq 0 ]
  echo "$output" | jq . >/dev/null
}

@test "relatorio-saude.sh -j JSON tem campos esperados" {
  run bash "$SCRIPT" -j
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.timestamp' >/dev/null
  echo "$output" | jq -e '.sistema.hostname' >/dev/null
  echo "$output" | jq -e '.cpu.uso_percentual' >/dev/null
  echo "$output" | jq -e '.memoria.uso_percentual' >/dev/null
  echo "$output" | jq -e '.disco' >/dev/null
  echo "$output" | jq -e '.processos.total' >/dev/null
}

@test "relatorio-saude.sh sem argumentos produz saída texto" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ SISTEMA ]]
  [[ "$output" =~ CPU ]]
  [[ "$output" =~ MEMÓRIA ]]
  [[ "$output" =~ DISCO ]]
  [[ "$output" =~ PROCESSOS ]]
}