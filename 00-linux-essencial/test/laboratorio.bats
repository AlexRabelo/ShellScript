#!/usr/bin/env bats
# Testes para laboratorio.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/laboratorio.sh"
}

@test "laboratorio.sh executa sem erro" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ Navegação ]]
  [[ "$output" =~ Criando\ e\ lendo\ arquivo ]]
  [[ "$output" =~ Procurando\ texto ]]
  [[ "$output" =~ Pipe ]]
  [[ "$output" =~ Copiando\ e\ movendo ]]
  [[ "$output" =~ Permissões ]]
  [[ "$output" =~ Redirecionamento\ de\ erro ]]
  [[ "$output" =~ Encontrando\ arquivos ]]
}

@test "laboratorio.sh cria estrutura em /tmp/lab-linux" {
  bash "$SCRIPT" >/dev/null
  [ -d "/tmp/lab-linux" ]
  [ -d "/tmp/lab-linux/logs" ]
  [ -d "/tmp/lab-linux/backup" ]
  [ -f "/tmp/lab-linux/anotacoes.txt" ]
  [ -f "/tmp/lab-linux/logs/app.log" ]
  [ -f "/tmp/lab-linux/backup/notas.bak" ]
  [ -f "/tmp/lab-linux/executavel.sh" ]
}

@test "laboratorio.sh demonstra permissões de executavel.sh" {
  bash "$SCRIPT" >/dev/null
  perms=$(stat -c "%a" /tmp/lab-linux/executavel.sh)
  [ "$perms" = "755" ]
}