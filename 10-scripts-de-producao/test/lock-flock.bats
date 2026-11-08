#!/usr/bin/env bats
# Testes para lock-flock.sh

setup() {
  # Caminho para o script sendo testado
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/lock-flock.sh"
  # Diretório temporário para testes
  BATS_TMPDIR="$BATS_TEST_TMPDIR"
  LOCK_FILE="$BATS_TMPDIR/lock-flock.test.lock"
}

teardown() {
  # Limpa arquivos de lock criados durante os testes
  rm -f "$LOCK_FILE" "$BATS_TMPDIR"/*.lock.* 2>/dev/null || true
}

@test "lock-flock.sh --help mostra uso e sai com 0" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ lock-flock.sh ]]
}

@test "lock-flock.sh sem argumentos falha com código 2" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
  [[ "$output" =~ informe exatamente 1 argumento ]]
}

@test "lock-flock.sh com argumento inválido falha com código 2" {
  run bash "$SCRIPT" -x
  [ "$status" -eq 2 ]
  [[ "$output" =~ opção inválida ]]
}

@test "lock-flock.sh dry-run não cria lock file" {
  run bash "$SCRIPT" -n "/tmp/teste-arquivo"
  [ "$status" -eq 0 ]
  [ ! -f "$LOCK_FILE" ]
  [[ "$output" =~ DRY-RUN ]] || [[ "$output" =~ [dry-run] ]]
}

@test "lock-flock.sh cria lock file em modo exec" {
  # Teste em background para evitar travamento
  timeout 5 bash "$SCRIPT" "/tmp/teste-arquivo" --exec & 
  sleep 1  # aguarda início
  
  # Verifica se lock file foi criado
  [ -f "$LOCK_FILE" ]
  
  # Limpa o processo em background
  pkill -P $$ bash 2>/dev/null || true
  wait $! 2>/dev/null || true
  
  # Aguarda remoção do lock
  sleep 2
  [ ! -f "$LOCK_FILE" ] || { echo "Lock file não foi removido"; false; }
}

@test "lock-flock.sh respeita opção --dry-run" {
  run bash "$SCRIPT" --dry-run "/tmp/teste"
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]] || [[ "$output" =~ [dry-run] ]]
  [ ! -f "$LOCK_FILE" ]
}

@test "lock-flock.sh aceita caminho absoluto como argumento" {
  run bash "$SCRIPT" "/tmp/arquivo-teste-absoluto"
  [ "$status" -eq 0 ]  # deve pelo menos validar argumentos
  [[ ! "$output" =~ informe exatamente 1 argumento ]]
}

@test "lock-flock.sh mostra mensagem quando lock já existe" {
  # Cria lock file manualmente
  echo "$$" > "$LOCK_FILE"
  
  # Tenta adquirir lock (deve falhar)
  run bash "$SCRIPT" "/tmp/teste" --exec
  [ "$status" -eq 1 ]  # código de erro para lock existente
  [[ "$output" =~ já existe outra execução ]] || [[ "$output" =~ lock ]]
  
  # Limpa
  rm -f "$LOCK_FILE"
}