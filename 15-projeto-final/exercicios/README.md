# Exercícios - Módulo 15: Projeto Final (SRE Toolkit)

## Objetivo
Consolidar todo o conhecimento do curso criando, testando e estendendo o **sre-toolkit** - um toolkit completo de automação SRE/Sysadmin.

## Pré-requisitos
- Módulos 00-14 concluídos
- `jq`, `curl`, `systemd` disponíveis
- Permissão `sudo` para instalar (opcional, pode rodar localmente)

---

## Exercício 1: Entendendo a Arquitetura (Análise)

**Enunciado:**
Explore a estrutura do `sre-toolkit` em `15-projeto-final/sre-toolkit/` e responda:

1. Qual é o ponto de entrada principal? Como ele descobre os subcomandos disponíveis?
2. Como as bibliotecas em `lib/` são compartilhadas entre os subcomandos?
3. Qual subcomando você usaria para:
   a) Verificar a saúde de um servidor web?
   b) Fazer backup rotativo de `/var/www`?
   c) Coletar diagnóstico completo para um incidente?
   d) Verificar healthcheck de endpoints HTTP?
4. O que faz a variável `DRY_RUN` e onde ela é definida?

**Entrega:** Respostas em arquivo de texto ou markdown.

---

## Exercício 2: Instalação e Configuração

**Enunciado:**
Instale o `sre-toolkit` localmente (sem `sudo`) e configure alertas:

1. Crie um diretório `~/bin` e adicione ao `PATH`
2. Copie `bin/sre-toolkit` para `~/bin/` e torne executável
3. Copie `lib/` e `comandos/` para `~/.local/share/sre-toolkit/`
4. Crie arquivo de configuração `~/.config/sre-toolkit.conf` com:
   ```bash
   ALERT_WEBHOOK_URL="https://webhook.site/seu-id-unico"
   BACKUP_RETENCAO_DIAS=14
   HEALTHCHECK_TIMEOUT=10
   ```
5. Teste: `sre-toolkit saude` e `sre-toolkit saude -j | jq .`

**Entrega:** Screenshot ou log da execução bem-sucedida.

---

## Exercício 3: Subcomando `saude` - Relatórios e JSON

**Enunciado:**
Use o subcomando `saude` para gerar relatórios:

1. Rode `sre-toolkit saude` e identifique: hostname, uptime, uso de CPU, uso de RAM, uso de disco
2. Rode `sre-toolkit saude -j` e salve em `saude.json`
3. Use `jq` para extrair apenas:
   - `.cpu.uso_percentual`
   - `.memoria.uso_percentual`
   - `.disco[0].uso_percentual`
4. Crie um script `monitora-saude.sh` que:
   - Rode `sre-toolkit saude -j`
   - Alerte (echo "ALERTA") se CPU > 80% OU RAM > 90% OU Disco > 90%
   - Rode a cada 60 segundos (use `watch` ou loop com `sleep`)

**Entrega:** Arquivo `saude.json` e script `monitora-saude.sh`.

---

## Exercício 4: Subcomando `disco` - Análise e Limpeza

**Enunciado:**
Analise e limpe diretórios temporários:

1. Crie diretório de teste: `mkdir -p /tmp/teste-disco/{logs,temp,cache}`
2. Crie arquivos com idades diferentes:
   ```bash
   # Arquivos recentes (1 dia)
   echo "recente" > /tmp/teste-disco/logs/app.log
   # Arquivos antigos (40 dias)
   touch -d "40 days ago" /tmp/teste-disco/logs/old.log
   touch -d "45 days ago" /tmp/teste-disco/temp/temp.txt
   touch -d "60 days ago" /tmp/teste-disco/cache/cache.dat
   ```
3. Rode: `sre-toolkit disco --dir /tmp/teste-disco --dias 30`
4. Rode: `sre-toolkit disco --dir /tmp/teste-disco --dias 30 --limpeza`
5. Rode: `sre-toolkit disco --dir /tmp/teste-disco --dias 30 -j | jq .`

**Entrega:** Saída dos 3 comandos acima e explicação do que foi removido.

---

## Exercício 5: Subcomando `backup` - Backup Rotativo

**Enunciado:**
Implemente e teste backup rotativo:

1. Crie estrutura: `mkdir -p /tmp/dados/{site,db} /tmp/backups`
2. Popule: `echo "conteúdo do site" > /tmp/dados/site/index.html` e `echo "dados db" > /tmp/dados/db/dados.sql`
3. Rode backup com retenção 3: `sre-toolkit backup -r 3 /tmp/dados /tmp/backups`
4. Repita 5 vezes (simule dias diferentes mudando o timestamp ou use `--dry-run`)
5. Verifique que só os 3 mais recentes permanecem
6. Verifique integridade: `sha256sum -c /tmp/backups/backup-*.sha256`

**Entrega:** Lista dos arquivos em `/tmp/backups` após 5 backups e verificação de integridade.

---

## Exercício 6: Subcomando `health` - Healthchecks

**Enunciado:**
Configure healthchecks para serviços e endpoints:

1. Crie arquivo `servicos.txt` com:
   ```
   sshd
   systemd-journald
   cron
   ```
2. Crie arquivo `endpoints.txt` com:
   ```
   https://httpbin.org/get
   https://httpbin.org/status/200
   https://httpbin.org/status/500
   ```
3. Rode: `sre-toolkit health -s servicos.txt -e endpoints.txt`
4. Rode: `sre-toolkit health -j -s servicos.txt -e endpoints.txt | jq .`
5. Crie script `healthcheck-loop.sh` que:
   - Rode healthcheck a cada 30s
   - Se houver falhas, execute `sre-toolkit incidente --dir /tmp/incidente-$(date +%F-%H%M%S)`
   - Pare após 3 ciclos ou se tudo OK

**Entrega:** Saída JSON do healthcheck e script `healthcheck-loop.sh`.

---

## Exercício 7: Subcomando `logs` - Análise de Logs

**Enunciado:**
Analise diferentes formatos de log:

1. Use o log de exemplo do módulo 08: `08-processamento-de-texto/exemplos/top-ips-nginx.sh /tmp/test.log 5` (cria log nginx)
2. Rode: `sre-toolkit logs -f nginx /tmp/test.log`
3. Rode: `sre-toolkit logs -f json -j /tmp/test.log | jq .`
4. Crie log JSON de aplicação:
   ```bash
   cat > /tmp/app.json.log << 'EOF'
   {"timestamp":"2026-10-15T10:00:00Z","level":"INFO","msg":"User login","user_id":123}
   {"timestamp":"2026-10-15T10:00:01Z","level":"ERROR","msg":"DB connection failed","error":"timeout"}
   {"timestamp":"2026-10-15T10:00:02Z","level":"INFO","msg":"Retry successful","user_id":123}
   {"timestamp":"2026-10-15T10:00:03Z","level":"WARN","msg":"High latency","latency_ms":1500}
   EOF
   ```
5. Rode: `sre-toolkit logs -f json /tmp/app.json.log`

**Entrega:** Saída da análise dos dois logs.

---

## Exercício 8: Subcomando `incidente` - Coleta de Diagnóstico

**Enunciado:**
Colete diagnóstico para troubleshooting:

1. Rode: `sre-toolkit incidente --dir /tmp/incidente-teste`
2. Liste os arquivos gerados: `ls -la /tmp/incidente-teste/`
3. Examine: `cat /tmp/incidente-teste/system_info.txt`
4. Rode coleta completa: `sre-toolkit incidente --coleta-completa --dir /tmp/incidente-completo`
5. Compacte: `tar -czf /tmp/incidente-completo.tar.gz -C /tmp incidente-completo`
6. Verifique tamanho: `du -h /tmp/incidente-completo.tar.gz`

**Entrega:** Lista de arquivos gerados e tamanho do arquivo compactado.

---

## Exercício 9: Extensão - Novo Subcomando `docker`

**Enunciado:**
Crie um novo subcomando `docker` para o toolkit:

1. Crie `comandos/docker.sh` baseado no template dos outros comandos
2. Implemente as funções:
   - `lista_containers()` - lista containers rodando e parados
   - `stats_containers()` - mostra CPU/Memória dos containers
   - `limpa_dangling()` - remove images/containers/volumes não usados
3. Opções: `-j|--json`, `-v|--verbose`, `--limpeza`
4. Teste: `sre-toolkit docker`, `sre-toolkit docker --limpeza -n` (dry-run)

**Dica:** Use `docker ps -a --format json`, `docker stats --no-stream --format json`, `docker system prune -f`

**Entrega:** Arquivo `comandos/docker.sh` funcional.

---

## Exercício 10: Integração Completa - Pipeline de Monitoramento

**Enunciado:**
Crie um script `monitoramento-completo.sh` que orquestre todo o toolkit:

```bash
#!/usr/bin/env bash
# monitoramento-completo.sh - Pipeline completo de monitoramento SRE

# 1. Healthcheck dos serviços críticos
# 2. Se falhar -> coleta incidente
# 3. Analisa logs de erro
# 4. Verifica disco
# 5. Envia alerta (webhook) se houver problemas
# 6. Gera relatório JSON consolidado
```

Requisitos:
- Use `set -Eeuo pipefail`
- Implemente `main()` com parse de argumentos
- Suporte `--dry-run`, `--verbose`, `--config`
- Use as bibliotecas do toolkit (`source "${LIB_DIR}/log.sh"` etc.)
- Saída JSON consolidada no final
- Código de saída: 0 = tudo OK, 1 = problemas detectados

**Entrega:** Script `monitoramento-completo.sh` completo e testado.

---

## Critérios de Avaliação

| Critério | Peso |
|----------|------|
| Funcionalidade (scripts rodam sem erro) | 40% |
| Uso correto de `set -Eeuo pipefail`, `local`, `readonly` | 20% |
| Tratamento de erros e sinais (`trap`) | 15% |
| Saída JSON válida e parseável | 10% |
| Documentação/comentários no código | 10% |
| Criatividade/extensão além do básico | 5% |

---

## Dicas

- Use `shellcheck` em todos os scripts criados
- Teste com `bash -n script.sh` antes de executar
- Consulte `templates/script-producao.sh` para padrão de cabeçalho
- Os gabaritos estão em `exercicios/gabarito/`

---

## Referências

- [sre-toolkit README](../sre-toolkit/README.md)
- [Módulo 10: Scripts de Produção](../10-scripts-de-producao/)
- [Módulo 11: Admin de Servidores](../11-administracao-de-servidores/)
- [Módulo 13: Observabilidade](../13-observabilidade/)
- [Módulo 14: AWS CLI, jq, Terraform](../14-aws-cli-jq-terraform/)