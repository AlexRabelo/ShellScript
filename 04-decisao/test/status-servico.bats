#!/usr/bin/env bats
# Testes para status-servico.sh

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../exemplos/status-servico.sh"
}

@test "status-servico.sh --help mostra uso" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Uso: ]]
}

@test "status-servico.sh sem argumentos falha" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "status-servico.sh -n dry-run executa sem erro" {
  run bash "$SCRIPT" -n ssh
  [ "$status" -eq 0 ]
  [[ "$output" =~ DRY-RUN ]]
}

@test "status-servico.sh com serviço válido (sshd ou systemd)" {
  # Testa com serviço que provavelmente existe
  run bash "$SCRIPT" systemd-journald
  # 0=ativo, 1=inativo, 2=falhou
  [ "$status" -le 2 ]
  [[ "$output" =~ Serviço ]]
  [[ "$output" =~ systemd-journald ]]
}