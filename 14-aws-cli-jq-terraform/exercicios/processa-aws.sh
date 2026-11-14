#!/usr/bin/env bash
# =============================================================================
# processa-aws.sh — Script COM AVISOS ShellCheck para corrigir (exercício)
# =============================================================================
# Autor: Alex Rabelo
# Versão: 1.0.0
# Descrição: Exercício proposital com avisos de quoting/ShellCheck para correção.
# Uso: ./processa-aws.sh
# Códigos de saída: 0 sucesso | 1 erro de execução
# =============================================================================

set -Eeuo pipefail

instances=$(aws ec2 describe-instances --output json)
ids=$(echo $instances | jq -r '.Reservations[].Instances[].InstanceId')
for id in $ids; do
  tipo=$(echo $instances | jq -r --arg id "$id" '.Reservations[].Instances[] | select(.InstanceId==$id) | .InstanceType')
  echo "ID: $id, Tipo: $tipo"
done

tags=$(aws ec2 describe-tags --output json)
count=$(echo $tags | jq '.Tags | length')
echo "Total tags: $count"

if [ $count -gt 100 ]; then
  echo "Muitas tags"
fi