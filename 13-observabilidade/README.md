# 13-observabilidade

## Objetivo
Implementar **observabilidade prática em shell**: healthchecks compostos, análise de logs (texto + JSON), alertas multi-canal, métricas Prometheus e dashboards HTML — tudo com scripts que rodam em produção.

## Analogia
> **Carro sem painel vs. F1 telemetria.** O carro comum tem velocímetro e luz de óleo. O F1 tem 300 sensores transmitindo em tempo real: temperatura pneu, pressão freio, desgaste motor, GPS, G-force. Seus scripts devem ser a telemetria: **métricas, logs, traces, alertas** — não só "funciona/não funciona".

## Conceitos-chave

| Pilar | Implementação Shell | Exemplo |
|-------|---------------------|---------|
| **Healthchecks** | HTTP (curl), TCP (nc/timeout), systemd, processo, custom | `healthcheck-http.sh`, `healthcheck-composto.sh` |
| **Logs** | Parse texto (awk/sed/grep), JSON Lines (jq), agregação temporal | `analisa-logs.sh`, `analisa-logs-app.sh` |
| **Alertas** | Webhook (Slack/Teams/Telegram/Email), deduplicação, severidade | `alerta-webhook.sh`, `recebe-alerta.sh` |
| **Métricas** | Formato Prometheus textfile (`metric{label="v"} 123`) | `coleta-metricas.sh`, `coleta-metricas-negocio.sh` |
| **Dashboards** | HTML estático auto-refresh, servido por nginx | `gera-dashboard.sh` |

## Exemplos

| Script | Descrição | Conceitos |
|--------|-----------|-----------|
| [`healthcheck-http.sh`](exemplos/healthcheck-http.sh) | HTTP healthcheck com timeout, retry, códigos esperados, JSON output | `curl -sf`, `--max-time`, retry loop, `jq` |
| [`analisa-logs.sh`](exemplos/analisa-logs.sh) | Análise nginx/access.log: top IPs, erros 4xx/5xx, latency, bandwidth | `awk`, `sort`, `uniq`, percentis, `--tempo` |
| [`coleta-metricas.sh`](exemplos/coleta-metricas.sh) | Coleta sistema (CPU, RAM, disco, rede) → Prometheus textfile | `/proc`, `df`, `free`, `ss`, textfile collector |
| [`alerta-webhook.sh`](exemplos/alerta-webhook.sh) | Envia alerta para Slack, Teams, Telegram, Webhook genérico, Email | `curl` POST JSON, template mensagem, `--canal` |

## Exercícios

Veja [`exercicios/README.md`](exercicios/README.md) para 5 exercícios:

1. **Healthcheck composto** - `healthcheck-composto.sh` (HTTP + TCP + systemd + processo, integra alerta-webhook)
2. **Análise logs app (JSON Lines)** - `analisa-logs-app.sh` (p50/p95/p99, error rate, top trace_ids)
3. **Alertmanager receiver** - `recebe-alerta.sh` + `.service` + `.socket` (HTTP listener, deduplicação 5min, roteamento por severidade)
4. **Métricas de negócio** - `coleta-metricas-negocio.sh` (file/db/api → Prometheus format, labels obrigatórios)
5. **Dashboard HTML** - `gera-dashboard.sh` (lê JSONs de healthchecks, gera index.html com auto-refresh, filtros JS)

Gabarito em [`exercicios/gabarito/`](exercicios/gabarito/) — 7 arquivos funcionais.

## Armadilhas Comuns

| Armadilha | Sintoma | Solução |
|-----------|---------|---------|
| `curl` sem timeout | Healthcheck trava indefinidamente | `curl -sf --max-time 5 --connect-timeout 2` |
| Parse JSON com `awk`/`sed` | Quebra em edge cases (escaping, nesting) | **Sempre use `jq`** |
| Alertmanager envia array `alerts` | Script espera objeto único | `jq -c '.alerts[]' | while read alert; do ...` |
| Deduplicação em memória | Perde estado no restart do receiver | Arquivo em `/tmp/alert-dedup/` com TTL (`find -mmin +5 -delete`) |
| Métricas Prometheus com labels inválidos | `textfile collector` rejeita | Regex `^[a-z_:][a-z0-9_:]*$`, escape valores com `jq -R @uri` |
| Percentis em `awk` | Lento/incorreto em arquivos grandes | `sort -n` + `awk` com índice, ou `datamash` se disponível |

## Referências

- [Prometheus Textfile Collector](https://prometheus.io/docs/instrumenting/exporters/#textfile-collector)
- [Alertmanager Webhook Config](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config)
- [JSON Lines spec](https://jsonlines.org/)
- `man curl` / `man jq` / `man awk`
- Template base: [`../templates/script-producao.sh`](../templates/script-producao.sh)

## Próximos Passos

Módulo 14: **AWS CLI, jq, Terraform** — Automação de nuvem: inventário, custos, drift detection, tagging compliance, state backup.