#!/usr/bin/env bats
# Testes para conceito-read.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/conceito-read.sh"
}

@test "conceito-read.sh com input simulado" {
  run bash -c "printf 'Teste\\ncaminho\\\\teste\\nsenha123\\n\\ns\\nola mundo\\n' | bash $SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Olá, Teste! ]]
  [[ "$output" =~ caminho\\teste ]]
  [[ "$output" =~ Senha lida (tamanho: 8) ]]
  [[ "$output" =~ Continuando ]]
  [[ "$output" =~ Palavras: ola mundo ]]
}