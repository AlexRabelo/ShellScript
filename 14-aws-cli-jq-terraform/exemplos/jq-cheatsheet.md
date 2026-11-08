# jq Cheatsheet para AWS

## Básicos

```bash
# Pretty print
jq . arquivo.json
cat arquivo.json | jq .

# Raw output (sem aspas)
jq -r '.chave' arquivo.json

# Compact output
jq -c . arquivo.json
```

## Filtros Comuns

```bash
# Seleciona campo
jq '.Instances[0].InstanceId'

# Múltiplos campos
jq '.Instances[] | {id: .InstanceId, type: .InstanceType, state: .State.Name}'

# Filtra array
jq '.Instances[] | select(.State.Name == "running")'

# Múltiplas condições
jq '.Instances[] | select(.State.Name == "running" and .InstanceType == "t3.medium")'
```

## Transformação

```bash
# Renomeia chaves
jq '.Instances[] | {instance_id: .InstanceId, instance_type: .InstanceType}'

# Adiciona campo calculado
jq '.Instances[] | . + {name: (.Tags[]? | select(.Key=="Name") | .Value // "sem-nome")}'

# Agrupa por campo
jq 'group_by(.InstanceType) | map({type: .[0].InstanceType, count: length})'

# Ordena
jq 'sort_by(.LaunchTime) | reverse'
```

## AWS CLI + jq Padrões

### EC2
```bash
# Lista instâncias running com Name tag
aws ec2 describe-instances --query 'Reservations[].Instances[]' --output json | \
jq -r '.[] | select(.State.Name=="running") | "\(.InstanceId)\t\(.InstanceType)\t\(.Tags[]? | select(.Key=="Name") | .Value // "sem-nome")"'

# Conta por tipo
aws ec2 describe-instances --output json | \
jq '.Reservations[].Instances[] | .InstanceType' | sort | uniq -c | sort -rn
```

### RDS
```bash
# Instâncias com status
aws rds describe-db-instances --output json | \
jq -r '.DBInstances[] | "\(.DBInstanceIdentifier)\t\(.Engine)\t\(.DBInstanceStatus)\t\(.DBInstanceClass)"'
```

### Cost Explorer
```bash
# Custo por serviço (últimos 30 dias)
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity DAILY --metrics UnblendedCost --group-by Type=DIMENSION,Key=SERVICE --output json | \
jq -r '.ResultsByTime[].Groups[] | "\(.Keys[0])\t\(.Metrics.UnblendedCost.Amount)\t\(.Metrics.UnblendedCost.Unit)"' | sort -k2 -nr
```

### S3
```bash
# Tamanho total dos buckets
aws s3api list-objects-v2 --bucket meu-bucket --output json | \
jq '[.Contents[].Size] | add / 1024 / 1024 / 1024'
```

### CloudWatch Logs
```bash
# Filtra logs por padrão
aws logs filter-log-events --log-group-name /aws/lambda/minha-funcao --filter-pattern "ERROR" --output json | \
jq -r '.events[] | "\(.timestamp)\t\(.message)"'
```

## Operadores Úteis

```bash
# Valor padrão
(.chave // "default")

# Comprimento
length

# Chaves do objeto
keys

# Converte para CSV
@csv

# Formata timestamp
(.timestamp | strftime("%Y-%m-%d %H:%M:%S"))

# Matemática
(.Metrics.UnblendedCost.Amount | tonumber | . * 100 | floor / 100)
```

## Construção de Objetos

```bash
# Cria objeto
jq -n --arg nome "teste" --argjson valor 123 '{nome: $nome, valor: $valor}'

# Adiciona a array
jq -n --argjson arr '[1,2]' --argjson item 3 '$arr + [$item]'

# Merge
jq -s '.[0] * .[1]' arquivo1.json arquivo2.json
```

## Dicas AWS

```bash
# Sempre use --output json com jq
aws ec2 describe-instances --output json | jq ...

# Use --query para pré-filtrar no servidor (mais rápido)
aws ec2 describe-instances --query 'Reservations[].Instances[].{Id: InstanceId, Type: InstanceType}' --output json | jq ...

# Combine múltiplas chamadas
jq -s '.[0] * .[1]' <(aws ec2 describe-instances --output json) <(aws ec2 describe-tags --output json)
```

## Debug

```bash
# Ver estrutura
jq 'paths' arquivo.json

# Ver tipos
jq 'map_values(type)' arquivo.json

# Conta elementos
jq 'length' arquivo.json
```