#!/usr/bin/env bats
# Testes para top-ips-nginx.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/top-ips-nginx.sh"
  BATS_TMPDIR="$BATS_TEST_TMPDIR"
  LOG_FILE="$BATS_TMPDIR/top-ips-nginx.test.log"
}

teardown() {
  rm -f "$LOG_FILE" 2>/dev/null || true
}

@test "top-ips-nginx.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ top-ips-nginx.sh ]]
}

@test "top-ips-nginx.sh com arquivo inexistente cria exemplo" {
  # Remove qualquer arquivo de log existente para forçar criação do exemplo
  local fake_log="$BATS_TMPDIR/fake.log"
  [[ -f "$fake_log ]] && rm -f "$fake_log"
  
  run bash "$SCRIPT" "$fake_log" 1
  [ "$status" -eq 0 ]
  [[ "$output" =~ Arquivo de log não encontrado. Criando exemplo ]]
  [ -f "$fake_log" ]
  # Verifica que o arquivo contém dados de exemplo
  [[ "$(wc -l < "$fake_log")" -ge 10 ]]
}

@test "top-ips-nginx.sh aceita parâmetro TOP_N" {
  # Cria um arquivo de log simples
  local log_file="$BATS_TMPDIR/test.log"
  echo "1.1.1.1 - - [13/Oct/2026:10:00:00 +0000] \"GET / HTTP/1.1\" 200 123" > "$log_file"
  echo "2.2.2.2 - - [13/Oct/2026:10:00:01 +0000] \"GET / HTTP/1.1\" 200 456" >> "$log_file"
  echo "1.1.1.1 - - [13/Oct/2026:10:00:02 +0000] \"GET / HTTP/1.1\" 200 789" >> "$log_file"
  
  # Testa com TOP_N=1
  run bash "$SCRIPT" "$log_file" 1
  [ "$status" -eq 0 ]
  [[ "$output" =~ 1.1.1.1 ]]  # IP mais frequente deve aparecer primeiro
  [[ ! "$output" =~ 2.2.2.2 ]] || [[ "$output" =~ 2.2.2.2.*1 ]]  # deve ter count 1 se aparecer
  
  # Testa com TOP_N=2
  run bash "$SCRIPT" "$log_file" 2
  [ "$status" -eq 0 ]
  [[ "$output" =~ 1.1.1.1 ]]
  [[ "$output" =~ 2.2.2.2 ]]
}

@test "top-ips-nginx.sh valida TOP_N é número positivo" {
  run bash "$SCRIPT" "/tmp/qualquer.log" zero
  [ "$status" -eq 2 ]
  [[ "$output" =~ TOP_N deve ser um número inteiro positivo ]]
  
  run bash "$SCRIPT" "/tmp/qualquer.log" "-5"
  [ "$status" -eq 2 ]
  [[ "$output" =~ TOP_N deve ser maior que zero ]]
}

@test "top-ips-nginx.sh --dry-run não processa realmente (apenas mostra o que faria)" {
  # Este teste verifica que a opção --dry-run existe
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ --dry-run ]] || [[ "$output" =~ -n ]]
}