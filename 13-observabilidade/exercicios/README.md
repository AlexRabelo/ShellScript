# Exercícios - Módulo 13: Observabilidade

## Pré-requisitos
- Módulos 10-12 completos (template produção, scripts admin, systemd timers)
- `jq`, `curl`, `awk`, `nc`/`ncat`/`timeout` instalados
- Entender formato Prometheus textfile collector

---

## Exercício 1: Healthcheck Composto com Dependências

### Enunciado
Crie `healthcheck-composto.sh` que verifica uma aplicação com múltiplas dependências:
1. HTTP endpoint principal (`/health`)
2. HTTP endpoint de readiness (`/ready`)
3. Porta TCP do banco (ex: 5432)
4. Porta TCP do cache (ex: 6379)
5. Verifica se processo principal está rodando (systemd)

### Requisitos
- [ ] Opções: `-j/--json`, `-v/--verbose`, `-t/--timeout`, `-r/--retries`
- [ ] Cada check é independente mas falha geral se QUALQUER falhar
- [ ] Saída JSON: array com cada check (nome, tipo, status, latência, erro)
- [ ] Exit code: 0 se todos OK, 1 se qualquer falha
- [ ] Integra com `alerta-webhook.sh` (chama automaticamente se `--alerta` e houver falha)
- [ ] Template produção completo

### Entrada esperada (arquivo de config)
```yaml
# healthcheck-config.yaml (ou JSON)
app:
  nome: "minha-api"
  health_endpoint: "https://api.exemplo.com/health"
  ready_endpoint: "https://api.exemplo.com/ready"
  db_host: "db.exemplo.com"
  db_port: 5432
  cache_host: "redis.exemplo.com"
  cache_port: 6379
  systemd_service: "minha-api"
```

### Entregável
`healthcheck-composto.sh` + exemplo de config

---

## Exercício 2: Análise de Logs de Aplicação (JSON Lines)

### Enunciado
Estenda `analisa-logs.sh` para suportar logs de aplicação estruturados (JSON Lines) com:
- Níveis: debug, info, warn, error, fatal
- Campos: timestamp, level, service, trace_id, span_id, message, duration_ms
- Agregações: contagem por nível, top errors, latência p50/p95/p99 por serviço, top trace_ids com erro

### Requisitos
- [ ] Nova opção `--formato json-app` (ou detecta automaticamente)
- [ ] Parseia timestamp ISO8601 (`2026-10-13T10:30:45.123Z`)
- [ ] Filtro temporal por `--tempo` funciona com timestamps ISO
- [ ] Métricas:
  - Contagem por level
  - Top 10 mensagens de erro (level >= warn)
  - Latência p50, p95, p99 por service (campo duration_ms)
  - Top 5 trace_ids com erro (para tracing)
  - Taxa de erro por minuto (error rate)
- [ ] Saída JSON estruturada para Grafana Loki / Elasticsearch
- [ ] Template produção

### Entregável
`analisa-logs-app.sh` (baseado no exemplo, estendido)

---

## Exercício 3: Alertmanager Webhook Receiver (Shell)

### Enunciado
Crie `recebe-alerta.sh` que roda como **serviço systemd** (Type=simple, porta 9093) e:
- Recebe POST do Alertmanager (JSON)
- Parseia alertas (labels, annotations, startsAt, endsAt, generatorURL)
- Roteia por severidade (critical → Telegram + Slack, warning → Slack, info → log)
- Deduplica alertas iguais em janela de 5 min (memória ou arquivo)
- Loga tudo em JSON estruturado
- Healthcheck endpoint `/health` na mesma porta

### Requisitos
- [ ] Usa `nc -l -k -p 9093` ou `socat` ou `python -m http.server` wrapper
- [ ] Melhor: `bash` com `coproc` ou named pipe para HTTP simples
- [ ] Parseia JSON do Alertmanager (array alerts)
- [ ] Extrai: alertname, severity, instance, job, summary, description
- [ ] Chama `alerta-webhook.sh` para cada canal
- [ ] Deduplicação: chave = alertname+instance+severity, TTL 5min
- [ ] systemd service com sandbox, User=alertmanager, porta 9093
- [ ] Graceful shutdown (SIGTERM fecha listener)

### Dica
Para HTTP simples em bash, pode usar:
```bash
# Com socat (mais robusto)
socat TCP-LISTEN:9093,reuseaddr,fork SYSTEM:"/caminho/handler.sh"

# Ou netcat loop (simples)
while true; do nc -l -p 9093 -q 1 < /caminho/handler.sh; done
```

### Entregável
`recebe-alerta.sh` + `recebe-alerta.service` + `recebe-alerta.handler.sh`

---

## Exercício 4: Métricas Customizadas de Negócio

### Enunciado
Crie `coleta-metricas-negocio.sh` que coleta métricas específicas da aplicação:
- Lê de arquivo compartilhado (ex: `/var/lib/app/metrics.json` escrito pela app)
- Ou executa query no banco (ex: `psql -c "SELECT count(*) FROM pedidos WHERE status='pendente'"`)
- Ou chama API interna (`curl http://localhost:8080/metrics`)
- Exporta no formato Prometheus com prefixo `app_`

### Requisitos
- [ ] Fonte configurável: `-s/--source file|db|api`
- [ ] Se file: lê JSON com estrutura `{metric_name: value, labels: {k:v}}`
- [ ] Se db: `-q/--query` + `-d/--dsn` (PostgreSQL/MySQL)
- [ ] Se api: `-u/--url` + `-H/--header` (Bearer token)
- [ ] Validação: métricas devem ter nome válido Prometheus (regex `^[a-z_:][a-z0-9_:]*$`)
- [ ] Labels obrigatórios: `app="meu-app"`, `environment="prod"`
- [ ] Timestamp opcional (usa now se não informado)
- [ ] Template produção, dry-run mostra métricas que seriam escritas

### Entregável
`coleta-metricas-negocio.sh`

---

## Exercício 5: Dashboard de Status (HTML Gerado por Shell)

### Enunciado
Crie `gera-dashboard.sh` que gera um **HTML estático** com status de todos os healthchecks:
- Lê resultados JSON de múltiplos `healthcheck-*.sh` (arquivos em `/var/lib/healthchecks/`)
- Gera `index.html` com tabela colorida (verde/amarelo/vermelho)
- Auto-refresh a cada 30s (meta refresh ou JS)
- Inclui: timestamp última verificação, latência, uptime, links para logs
- Deployável via nginx/apache servindo `/var/www/status/`

### Requisitos
- [ ] Input: diretório com arquivos `*.json` (um por healthcheck)
- [ ] Output: `index.html` + `style.css` + `script.js` (inline ou separados)
- [ ] Tabela: Serviço | Status | Última verificação | Latência | Detalhes
- [ ] Cores: OK=verde, DEGRADED=amarelo, DOWN=vermelho
- [ ] Badge com contagem: "12 OK, 2 DEGRADED, 1 DOWN"
- [ ] Filtro JS por status
- [ ] Template produção, dry-run mostra HTML no stdout

### Entregável
`gera-dashboard.sh` + assets (CSS/JS inline)

---

## Como Testar

```bash
# Healthcheck composto
./healthcheck-composto.sh -j -c config.yaml
./healthcheck-composto.sh --alerta -c config.yaml  # Dispara alerta se falha

# Análise logs app
./analisa-logs-app.sh -j -f json-app /var/log/app.json.log

# Métricas negócio
./coleta-metricas-negocio.sh -s file -f /var/lib/app/metrics.json --dry-run

# Dashboard
./gera-dashboard.sh -i /var/lib/healthchecks -o /var/www/status --dry-run

# Alert receiver (em VM com systemd)
sudo cp recebe-alerta.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now recebe-alerta
curl -X POST http://localhost:9093 -d '{"alerts":[{"labels":{"alertname":"Test","severity":"critical"}]}}'
```

---

## Critérios de Avaliação

| Critério | Peso |
|----------|------|
| Template produção aplicado | 20% |
| Funcionalidade completa | 25% |
| Integração entre scripts (healthcheck → alerta) | 15% |
| Formato Prometheus/JSON correto | 15% |
| ShellCheck zero avisos | 10% |
| Documentação auto-explicativa | 15% |

---

## Dicas

> **Healthcheck composto:** use funções para cada check, array de resultados, `jq` para montar JSON final.

> **Alertmanager receiver:** Alertmanager envia `Content-Type: application/json` com body `{"receiver":"...", "status":"firing", "alerts":[...], "groupLabels":{}, "commonLabels":{}, "commonAnnotations":{}, "externalURL":"..."}`.

> **Deduplicação:** arquivo em `/tmp/alert-dedup/` com timestamp, `find -mmin +5 -delete` antes de processar.

> **Prometheus labels:** nomes só com `[a-z0-9_]`, valores escapados. Use `jq -R @uri` para escapar.

> **HTML dashboard:** `cat <<'EOF' ... EOF` para heredoc com variáveis, ou `awk`/`sed` para template.