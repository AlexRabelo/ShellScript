# Exercícios - Módulo 14: AWS CLI, jq, Terraform

## Pré-requisitos
- Módulos 10-13 completos
- AWS CLI v2 configurado (`aws configure`)
- Terraform >= 1.0 instalado
- `jq` instalado
- Conta AWS com permissões adequadas (ou sandbox)

---

## Exercício 1: Inventário Multi-Região com Filtros

### Enunciado
Crie `aws-inventory-multi.sh` que estende `aws-inventory.sh` para:
- Suportar múltiplas regiões simultâneas (`-r us-east-1,us-west-2,eu-west-1`)
- Filtro por tags (`--tag Environment=prod,Team=backend`)
- Saída consolidada com região em cada recurso
- Opção `--resumo` que mostra contagem por tipo/região

### Requisitos
- [ ] Parse de regiões separadas por vírgula
- [ ] Loop sobre regiões (paralelo com `xargs -P` ou sequencial)
- [ ] Filtro JMESPath/JQ por tags
- [ ] Opção `--resumo` com tabela: REGIÃO | EC2 | RDS | S3 | LAMBDA | TOTAL
- [ ] JSON consolidado com campo `region` em cada recurso
- [ ] Template produção (set -euo pipefail, trap, log, dry-run)
- [ ] Passa no `shellcheck`

### Entregável
`aws-inventory-multi.sh`

---

## Exercício 2: Anomalia de Custos com Alertas

### Enunciado
Crie `aws-cost-anomalia.sh` que:
- Consulta Cost Explorer dos últimos N dias
- Calcula média móvel de 7 dias por serviço
- Detecta anomalias: gasto do dia > média * 1.5 (configurável)
- Integra com `alerta-webhook.sh` (Módulo 13) para notificar
- Saída: relatório JSON + alerta se houver anomalia

### Requisitos
- [ ] Parâmetros: `-d DIAS`, `-t THRESHOLD` (padrão 1.5), `--alerta`
- [ ] Média móvel calculada com `jq` (reduce/map)
- [ ] Compara último dia vs média 7 dias anteriores
- [ ] Se anomalia: chama `alerta-webhook.sh -c slack ...` com detalhes
- [ ] Saída JSON: `{anomalias: [...], periodo: "...", threshold: 1.5}`
- [ ] Template produção + dry-run

### Entregável
`aws-cost-anomalia.sh`

---

## Exercício 3: Terraform Plan Parser com Drift

### Enunciado
Crie `terraform-plan-analyzer.sh` que:
- Executa `terraform plan -out=tfplan` e converte para JSON (`terraform show -json tfplan`)
- Analisa mudanças planejadas: create, update, delete, replace
- Detecta substituições perigosas (replace de recursos stateful: RDS, S3, DynamoDB)
- Gera relatório de risco: ALTO (replace stateful), MÉDIO (update), BAIXO (create/delete)
- Integra drift detection do `terraform-drift.sh` (Módulo 14)

### Requisitos
- [ ] Parse `terraform show -json` com jq
- [ ] Classifica cada change: `create`, `update`, `delete`, `replace`
- [ ] Lista de recursos stateful: `aws_db_instance`, `aws_s3_bucket`, `aws_dynamodb_table`, `aws_ebs_volume`
- [ ] Risk score: replace stateful=10, replace outros=5, update=2, create/delete=1
- [ ] Saída JSON: `{risk_score: N, changes: [...], drift: [...], recomendacao: "..."}`
- [ ] Exit code: 0 (baixo risco), 1 (médio), 2 (alto)
- [ ] Template produção + dry-run

### Entregável
`terraform-plan-analyzer.sh`

---

## Exercício 4: AWS Resource Tagging Compliance

### Enunciado
Crie `aws-tag-compliance.sh` que:
- Varre recursos em regiões especificadas (EC2, RDS, S3, Lambda, ELB)
- Verifica tags obrigatórias: `Environment`, `Owner`, `CostCenter`, `Project`
- Gera relatório de conformidade: % compliant, lista non-compliant
- Auto-remediação opcional (`--apply`) que adiciona tags padrão onde faltam
- Integra com `alerta-webhook.sh` para reportar non-compliance

### Requisitos
- [ ] Tags obrigatórias configuráveis via arquivo JSON ou flags
- [ ] Suporta EC2, RDS, S3, Lambda, ELBv2
- [ ] Relatório: TOTAL | COMPLIANT | NON_COMPLIANT | % por recurso
- [ ] `--apply` usa `aws resourcegroupstaggingapi tag-resources` ou APIs específicas
- [ ] Dry-run mostra o que seria taggeado
- [ ] JSON output para dashboard
- [ ] Template produção

### Entregável
`aws-tag-compliance.sh`

---

## Exercício 5: Terraform State Backup & Restore

### Enunciado
Crie `terraform-state-backup.sh` que:
- Faz backup do state Terraform (local ou remoto S3)
- Versiona backups com timestamp + hash do state
- Mantém retenção de N backups (padrão: 30)
- Testa restore em diretório temporário (`terraform init -backend-config=...`)
- Valida integridade: `terraform state list` funciona no restore

### Requisitos
- [ ] Backend local: copia `terraform.tfstate`
- [ ] Backend S3: usa `aws s3 cp` com versionamento
- [ ] Naming: `terraform.tfstate.YYYYMMDD-HHMMSS.<sha256>.bak`
- [ ] Retenção: remove backups antigos (mantém N)
- [ ] `--test-restore`: restaura em `/tmp/tf-restore-XXXXX` e valida
- [ ] `--list`: lista backups disponíveis com metadados
- [ ] Template produção + dry-run

### Entregável
`terraform-state-backup.sh`

---

## Exercício 6: jq Avançado - Transformação de Dados AWS (ShellCheck)

### Enunciado
O script abaixo processa saída do AWS CLI. Tem **10+ avisos ShellCheck**. Corrija todos.

```bash
#!/usr/bin/env bash
# processa-aws.sh

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
```

### Avisos esperados
- SC2086: aspas em expansões
- SC2046: command substitution sem aspas
- SC2155: declaração/atribuição separadas
- SC2126: `grep -c` vs `wc -l`
- SC2034: variável não usada
- SC2162: `read` sem `-r`
- SC2002: `cat` desnecessário (usar `<` ou pipe)
- SC2012: `find` sem `-type f`
- SC2143: `grep` para verificar existência
- SC2207: `mapfile` ao invés de `read` em loop

### Entregável
`processa-aws-corrigido.sh` (zero avisos)

---

## Como Testar

```bash
# Exercício 1
./aws-inventory-multi.sh -r us-east-1,us-west-2 --resumo
./aws-inventory-multi.sh -j -r us-east-1 --tag Environment=prod

# Exercício 2
./aws-cost-anomalia.sh -d 30 -t 2.0 --alerta --dry-run
./aws-cost-anomalia.sh -j -d 7

# Exercício 3
cd /caminho/projeto-terraform
./terraform-plan-analyzer.sh -j --dry-run

# Exercício 4
./aws-tag-compliance.sh -r us-east-1 --apply --dry-run

# Exercício 5
./terraform-state-backup.sh --list
./terraform-state-backup.sh --test-restore

# Exercício 6
shellcheck processa-aws-corrigido.sh
bash -n processa-aws-corrigido.sh
```

---

## Critérios de Avaliação

| Critério | Peso |
|----------|------|
| Template produção aplicado | 20% |
| AWS CLI + jq correto | 25% |
| Lógica de negócio (anomalia, drift, compliance) | 20% |
| Integração Módulo 13 (alerta-webhook) | 10% |
| ShellCheck zero avisos | 10% |
| Documentação auto-explicativa | 15% |

---

## Dicas

> **Cost Explorer:** `ce:GetCostAndUsage` precisa de permissão explícita. Use `--dry-run` para testar lógica sem chamar API.

> **Terraform JSON:** `terraform show -json` gera estrutura complexa. Use `jq '.resource_changes[] | select(.change.actions[] == "replace")'` para achar replaces.

> **Tags:** `resourcegroupstaggingapi` é unificado mas lento. Para EC2/RDS/S3, use APIs nativas (`create-tags`, `add-tags-to-resource`).

> **Drift:** `terraform state show` é mais confiável que `terraform state list` + parse.

> **JQ Performance:** Use `--arg`/`--argjson` para passar variáveis shell, não interpolação de string.