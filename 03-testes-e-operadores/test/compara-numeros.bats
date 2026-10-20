#!/usr/bin/env bats
# Testes para compara-numeros.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/compara-numeros.sh"
}

@test "compara-numeros.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "compara-numeros.sh sem argumentos falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "compara-numeros.sh 10 5 mostra 10 maior que 5" {
  run bash "$SCRIPT" 10 5
  [ "$status" -eq 0 ]
  [[ "$output" =~ 10 é maior que 5 ]]
  [[ "$output" =~ 10 é diferente de 5 ]]
}

@test "compara-numeros.sh 3 3 mostra igualdade" {
  run bash "$SCRIPT" 3 3
  [ "$status" -eq 0 ]
  [[ "$output" =~ 3 é igual a 3 ]]
}

@test "compara-numeros.sh com não-número falha" {
  run bash "$SCRIPT" abc 5
  [ "$status" -eq 2 ]
  [[ "$output" =~ deve ser um número ]]
}