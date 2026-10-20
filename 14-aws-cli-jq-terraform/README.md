# 14-aws-cli-jq-terraform

## Objetivo
Automação **AWS com shell nativo**: inventário multi-região, análise de custos, drift detection Terraform, tagging compliance, state backup. Integra com observabilidade (Módulo 13) para alertas.

## Analogia
> **Console AWS = painel de controle manual.** Clique, filtre, exporte CSV, repita amanhã.
> **Shell + AWS CLI + jq = API programável.** Um script faz em 5 segundos o que leva 30 min no console: "liste todos RDS não criptografados em 3 regiões", "alarme se custo EC2 subir 50%", "detecte drift no Terraform antes do apply".

## Conceitos-chave

| Área | Ferramentas | Padrão Shell |
|------|-------------|--------------|
| **Inventário** | `aws ec2/rds/s3/lambda describe-*` + `jq` JMESPath | Loop regiões, `--output json`, `jq` flatten |
| **Custos** | `aws ce get-cost-and-usage` + `jq` reduce/map | Média móvel 7d, detecção anomalia (threshold) |
| **Terraform** | `terraform plan -out` + `show -json` + `jq` | Classificação create/update/delete/replace, risk score |
| **Tagging** | `resourcegroupstaggingapi` + APIs nativas | Compliance % + auto-remediação `--apply` |
| **State** | `aws s3 cp` (backend S3) / `cp` (local) + `sha256` | Versionamento timestamp+hash, retenção, test-restore |

## Exemplos

| Script | Descrição | Conceitos |
|--------|-----------|-----------|
| [`aws-inventory.sh`](exemplos/aws-inventory.sh) | Inventário EC2/RDS/S3/Lambda/ELB em uma região, JSON consolidado | `aws cli`, `jq` JMESPath, `--tag` filter, `--resumo` |
| [`aws-cost.sh`](exemplos/aws-cost.sh) | Consulta Cost Explorer, últimos N dias, por serviço, JSON | `ce:GetCostAndUsage`, `jq` group_by, formatação |
| [`terraform-drift.sh`](exemplos/terraform-drift.sh) | `terraform plan -detailed-exitcode` + parse output, detecta drift | `terraform` exit codes (0=ok, 1=error, 2=changes), JSON |
| [`jq-cheatsheet.md`](exemplos/jq-cheatsheet.md) | Referência rápida: filter, map, select, reduce, group_by, @csv/@tsv | Padrões `jq` mais usados em automação AWS |

## Exercícios

Veja [`exercicios/README.md`](exercicios/README.md) para 6 exercícios:

1. **Inventário multi-região** - `aws-inventory-multi.sh` (regiões CSV, tag filter, `--resumo` tabela, JSON consolidado)
2. **Anomalia de custos** - `aws-cost-anomalia.sh` (média móvel 7d, threshold configurável, integra `alerta-webhook.sh`)
3. **Terraform plan analyzer** - `terraform-plan-analyzer.sh` (risk score: replace stateful=10, update=2, exit code por risco)
4. **Tag compliance** - `aws-tag-compliance.sh` (tags obrigatórias, % compliant, `--apply` auto-tag, alerta non-compliant)
5. **State backup/restore** - `terraform-state-backup.sh` (local/S3, timestamp+hash, retenção, `--test-restore`, `--list`)
6. **ShellCheck: processa AWS** - `processa-aws-corrigido.sh` (10+ avisos corrigidos, `mapfile`, `jq --arg`, aspas)

Gabarito em [`exercicios/gabarito/`](exercicios/gabarito/).

## Armadilhas Comuns

| Armadilha | Sintoma | Solução |
|-----------|---------|---------|
| `aws cli` paginação | `describe-instances` retorna só 1000 | Use `--max-items` + `--starting-token` ou `aws ec2 describe-instances --query 'Reservations[].Instances[]'` |
| `jq` interpolação de string | `jq ".Reservations[].Instances[] | select(.InstanceId==\"$id\")"` quebra em aspas | **Use `--arg id "$id"`**: `jq --arg id "$id" '.[] | select(.InstanceId==$id)'` |
| Cost Explorer permissions | `AccessDenied` em `ce:GetCostAndUsage` | Policy: `ce:GetCostAndUsage`, `ce:GetDimensionValues` na conta master/payer |
| Terraform JSON structure | `resource_changes` array complexo | `jq '.resource_changes[] | select(.change.actions[] == "replace")'` para achar replaces |
| Tagging API rate limits | `Throttling` em frota grande | `xargs -P 5 -n 20` + `sleep 0.1` entre batches, exponential backoff |
| State file locking | `Error acquiring state lock` | S3 backend com DynamoDB locking; local: `flock` no script |

## jq Patterns Úteis (do `jq-cheatsheet.md`)

```bash
# Filtrar por tag
aws ec2 describe-instances --query 'Reservations[].Instances[]' --output json \
  | jq 'select(.Tags[]? | select(.Key=="Environment" and .Value=="prod"))'

# Agrupar por tipo e contar
jq 'group_by(.InstanceType) | map({tipo: .[0].InstanceType, count: length})'

# Média móvel 7 dias (Cost Explorer)
jq '[.ResultsByTime[].Groups[] | {service: .Keys[0], amount: .Metrics.BlendedCost.Amount | tonumber}] 
    | group_by(.service) | map({service: .[0].service, avg7d: (map(.amount) | add/length)})'

# Terraform risk score
jq '.resource_changes[] 
    | .change.actions[] as $a 
    | select($a=="replace") 
    | .address 
    | if test("aws_(db_instance|s3_bucket|dynamodb_table|ebs_volume)") then 10 else 5 end'
```

## Referências

- [AWS CLI Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Terraform CLI](https://developer.hashicorp.com/terraform/cli/commands)
- [AWS Cost Explorer API](https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/Welcome.html)
- Template base: [`../templates/script-producao.sh`](../templates/script-producao.sh)

## Próximos Passos

Módulo 15: **Projeto Final (SRE Toolkit)** — Consolida tudo em um CLI único: `sre-toolkit saude|disco|backup|health|logs|aws|incidente`.