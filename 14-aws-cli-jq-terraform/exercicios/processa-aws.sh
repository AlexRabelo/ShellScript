#!/usr/bin/env bash
# processa-aws.sh - Script COM AVISOS ShellCheck para corrigir

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