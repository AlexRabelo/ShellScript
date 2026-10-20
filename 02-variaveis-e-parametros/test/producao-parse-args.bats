#!/usr/bin/env bats
# Testes para producao-parse-args.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/producao-parse-args.sh"
}

@test "producao-parse-args.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ producao-parse-args.sh ]]
}

@test "producao-parse-args.sh sem argumentos falha com código 2" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "producao-parse-args.sh -n dry-run com servidores" {
  run bash "$SCRIPT" -n web01 web02
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [[ "$output" =~ web01 ]]
  [[ "$output" =~ web02 ]]
}

@test "producao-parse-args.sh -p porta válida" {
  run bash "$SCRIPT" -n -p 8080 web01
  [ "$status" -eq 0 ]
}

@test "producao-parse-args.sh -p porta inválida falha" {
  run bash "$SCRIPT" -n -p 99999 web01
  [ "$status" -eq 2 ]
  [[ "$output" =~ Porta inválida ]]
}

@test "producao-parse-args.sh -a ambiente válido" {
  run bash "$SCRIPT" -n -a homolog web01
  [ "$status" -eq 0 ]
}

@test "producao-parse-args.sh -a ambiente inválido falha" {
  run bash "$SCRIPT" -n -a invalido web01
  [ "$status" -eq 2 ]
  [[ "$output" =~ Ambiente inválido ]]
}