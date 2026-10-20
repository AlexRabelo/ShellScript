#!/usr/bin/env bats
# Testes para modo-estrito.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/modo-estrito.sh"
  BATS_TMPDIR="$BATS_TEST_TMPDIR"
}

@test "modo-estrito.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ modo-estrito.sh ]]
}

@test "modo-estrito.sh --sem-estrito mostra comportamento perigoso (mas não falha)" {
  # Este teste verifica que a versão sem modo estrito não aborta imediatamente
  # Em modo estrito, variáveis não definidas causariam aborto
  run bash "$SCRIPT" --sem-estrito
  [ "$status" -eq 0 ]  # deve completar (mesmo com comportamento perigoso)
  [[ "$output" =~ VERSÃO SEM MODO ESTRITO ]]
  [[ "$output" =~ Diretório alvo: ]]
}

@test "modo-estrito.sh --com-estrito demonstra proteção" {
  # Testa que a versão com modo estrito protege contra erros comuns
  # Note: o script já trata estes erros em subshells isolados
  run bash "$SCRIPT" --com-estrito
  [ "$status" -eq 0 ]  # deve completar graças aos subshells
  [[ "$output" =~ VERSÃO COM MODO ESTRITO ]]
  [[ "$output" =~ Subshell abortou como esperado ]]
}

@test "modo-estrito.sh demonstra armadilha do set -e" {
  run bash "$SCRIPT" --armadilha
  [ "$status" -eq 0 ]
  [[ "$output" =~ ARMADILHA: set -e NÃO dispara em contextos condicionais ]]
  [[ "$output" =~ Solução: usar 'set -E' ]]
}

@test "modo-estrito.sh sem argumentos demonstra ambos os modos" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ VERSÃO SEM MODO ESTRITO ]]
  [[ "$output" =~ VERSÃO COM MODO ESTRITO ]]
  [[ "$output" =~ ARMADILHA: set -e NÃO dispara ]]
}