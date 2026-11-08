#!/usr/bin/env bats
# Testes para dry-run.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/dry-run.sh"
  BATS_TMPDIR="$BATS_TEST_TMPDIR"
  TEST_DIR="$BATS_TMPDIR/teste-dry-run"
  TEST_FILE="$TEST_DIR/arquivo-teste.txt"
}

teardown() {
  rm -rf "$TEST_DIR" 2>/dev/null || true
}

@test "dry-run.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
  [[ "$output" =~ dry-run.sh ]]
}

@test "dry-run.sh padrão é dry-run (apenas lista)" {
  mkdir -p "$TEST_DIR"
  echo "conteúdo de teste" > "$TEST_FILE"
  
  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]] || [[ "$output" =~ Modo DRY-RUN ]]
  [[ "$output" =~ $TEST_FILE ]]
  # Verifica que o arquivo NÃO foi modificado
  [ -f "$TEST_FILE" ]
  [[ "$(cat "$TEST_FILE")" == "conteúdo de teste ]]
}

@test "dry-run.sh --exec realmente executa a ação" {
  mkdir -p "$TEST_DIR"
  echo "conteúdo de teste" > "$TEST_FILE"
  
  run bash "$SCRIPT" "$TEST_DIR" --exec
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ DRY-RUN ]] || [[ ! "$output" =~ Modo DRY-RUN ]]
  # O diretório deve estar vazio agora (arquivos .txt removidos)
  [ ! -f "$TEST_FILE" ]
  [ -d "$TEST_DIR" ]  # diretório ainda existe
}

@test "dry-run.sh respeita opção -n (alias para --dry-run)" {
  mkdir -p "$TEST_DIR"
  echo "test" > "$TEST_DIR/test.txt"
  
  run bash "$SCRIPT" -n "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]] || [[ "$output" =~ [dry-run] ]]
  [ -f "$TEST_DIR/test.txt" ]  # arquivo preservado
}

@test "dry-run.sh falha com diretório inexistente" {
  run bash "$SCRIPT" "/tmp/diretorio-inexistente-xyz"
  [ "$status" -eq 1 ]
  [[ "$output" =~ Diretor.*não existe ]] || [[ "$output" =~ not found ]]
}

@test "dry-run.sh processa arquivos .log e .log.* corretamente" {
  mkdir -p "$TEST_DIR"
  echo "antigo" > "$TEST_DIR/antigo.log"
  echo "recente" > "$TEST_DIR/recente.log"
  echo "outro" > "$TEST_DIR/outro.txt"
  
  # Faz o arquivo antigo parecer velho (modifica mtime)
  touch -d "2 days ago" "$TEST_DIR/antigo.log"
  
  # Testa dry-run padrão (7 dias)
  run bash "$SCRIPT" "$TEST_DIR" 0  # 0 dias = tudo mais velho que hoje
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
  [[ "$output" =~ $TEST_DIR/antigo.log ]] || [[ "$output" =~ $TEST_DIR/recente.log ]]
  # Ambos devem aparecer como candidatos para remoção com 0 dias
  
  # Verifica que nenhum arquivo foi realmente removido
  [ -f "$TEST_DIR/antigo.log" ]
  [ -f "$TEST_DIR/recente.log" ]
  [ -f "$TEST_DIR/outro.txt" ]
}