# Módulo 15: Projeto Final - SRE Toolkit

> **Consolidação:** Este módulo integra todos os conceitos dos módulos 00-14 em um toolkit real de automação SRE/Sysadmin, pronto para uso em produção.

## Objetivos

Ao final deste módulo você será capaz de:

- Entender a arquitetura modular de um toolkit CLI profissional
- Instalar, configurar e usar o **sre-toolkit** completo
- Estender o toolkit com novos subcomandos
- Orquestrar múltiplas funcionalidades em pipelines de monitoramento
- Aplicar boas práticas de scripts de produção (módulo 10)
- Integrar observabilidade, alertas, backup e diagnóstico

## Visão Geral do sre-toolkit

O **sre-toolkit** é uma ferramenta de linha de comando única (`sre-toolkit`) com subcomandos que cobrem o ciclo de vida completo de operações SRE:

| Subcomando | Descrição | Módulos Base |
|------------|-----------|--------------|
| `saude` | Relatório de saúde do servidor (CPU, RAM, disco, processos) | 10, 11 |
| `disco` | Análise e limpeza inteligente de disco com retenção | 10, 11 |
| `backup` | Backup rotativo com verificação de integridade (SHA256) | 10, 11 |
| `health` | Healthcheck de serviços systemd e endpoints HTTP/TCP | 12, 13 |
| `logs` | Análise de logs (nginx, apache, json, syslog, genérico) | 8, 13 |
| `aws` | Inventário e análise de recursos AWS (EC2, RDS, S3, etc.) | 14 |
| `incidente` | Coleta de diagnóstico para troubleshooting | 10, 11, 13 |
| `docker` | *(extensão)* Gerenciamento de containers Docker | 9, 10 |

### Características de Produção

- 🔒 **Modo estrito**: `set -Eeuo pipefail` em todos os scripts
- 🛡️ **Tratamento de sinais**: `trap` para EXIT, INT, TERM, ERR com cleanup
- 🧪 **Dry-run**: Simula execuções sem alterar nada (`-n|--dry-run`)
- 📝 **Logging estruturado**: Níveis INFO, AVISO, ERRO, DEBUG com timestamps
- 📊 **Saída JSON**: Todos os subcomandos suportam `-j|--json` para integração
- 🔧 **Configuração externa**: Arquivo `.conf` para alertas, AWS, retenção
- 🔔 **Alertas multi-canal**: Slack, Teams, Telegram, Webhook, Email, stdout
- 🐳 **Extensível**: Adicionar subcomandos copiando template

## Estrutura do Projeto

```
15-projeto-final/
├── README.md                 # Este arquivo
├── sre-toolkit/              # Toolkit completo
│   ├── bin/
│   │   └── sre-toolkit       # Ponto de entrada principal
│   ├── lib/                  # Bibliotecas compartilhadas
│   │   ├── log.sh            # Logging padronizado
│   │   ├── valida.sh         # Validações comuns
│   │   ├── alerta.sh         # Alertas multi-canal
│   │   └── util.sh           # Utilitários (run, lock, tmp, bytes, timestamp)
│   ├── comandos/             # Subcomandos (um arquivo cada)
│   │   ├── saude.sh
│   │   ├── disco.sh
│   │   ├── backup.sh
│   │   ├── health.sh
│   │   ├── logs.sh
│   │   ├── aws.sh
│   │   ├── incidente.sh
│   │   └── docker.sh         # Exercício de extensão
│   ├── config/
│   │   └── sre-toolkit.conf.example  # Template de configuração
│   ├── systemd/              # Templates systemd timer/service
│   │   ├── sre-toolkit-health.service
│   │   └── sre-toolkit-health.timer
│   ├── testes/               # Testes BATS (a implementar)
│   ├── Makefile              # Instalação automatizada
│   ├── LICENSE
│   └── README.md             # Documentação do toolkit
├── exercicios/               # Exercícios consolidados
│   ├── README.md             # 10 exercícios progressivos
│   └── gabarito/             # Soluções completas
│       ├── respostas.md
│       ├── monitora-saude.sh
│       ├── healthcheck-loop.sh
│       ├── docker.sh
│       └── monitoramento-completo.sh
└── test_debug.sh             # Scripts de depuração (legado)
```

## Instalação Rápida

### Opção 1: Make (recomendado)
```bash
cd 15-projeto-final/sre-toolkit
sudo make install
# Instala em /usr/local/sbin/sre-toolkit, /usr/local/sre-toolkit/, /etc/sre-toolkit/
```

### Opção 2: Manual (sem sudo)
```bash
# No diretório do projeto
mkdir -p ~/.local/bin ~/.local/share/sre-toolkit ~/.config

cp sre-toolkit/bin/sre-toolkit ~/.local/bin/
chmod +x ~/.local/bin/sre-toolkit

cp -r sre-toolkit/lib sre-toolkit/comandos ~/.local/share/sre-toolkit/

cp sre-toolkit/config/sre-toolkit.conf.example ~/.config/sre-toolkit.conf
chmod 600 ~/.config/sre-toolkit.conf

# Adicionar ao PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Opção 3: Direto do repositório
```bash
# Para desenvolvimento/teste direto
export TOOLKIT_ROOT="$(pwd)/15-projeto-final/sre-toolkit"
export LIB_DIR="${TOOLKIT_ROOT}/lib"
export COMANDOS_DIR="${TOOLKIT_ROOT}/comandos"
export CONFIG_FILE="${TOOLKIT_ROOT}/config/sre-toolkit.conf.example"
PATH="${TOOLKIT_ROOT}/bin:$PATH"
```

## Configuração

Edite `~/.config/sre-toolkit.conf` (ou `/etc/sre-toolkit/sre-toolkit.conf`):

```bash
# Alertas (configure pelo menos um)
ALERT_WEBHOOK_URL="https://webhook.site/seu-id"
ALERT_SLACK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
ALERT_TEAMS_URL="https://outlook.office.com/webhook/XXX"
ALERT_TELEGRAM_BOT_TOKEN="123456:ABC-DEF"
ALERT_TELEGRAM_CHAT_ID="-1001234567890"

# Backup
BACKUP_RETENCAO_DIAS=14

# Healthcheck
HEALTHCHECK_TIMEOUT=10

# AWS
AWS_DEFAULT_REGION="us-east-1"
AWS_PROFILE="default"

# Logs
LOG_FILE="/var/log/sre-toolkit.log"
```

## Uso Básico

```bash
# Ver ajuda geral
sre-toolkit --help

# Ver ajuda de subcomando
sre-toolkit saude --help

# Relatório de saúde (texto)
sre-toolkit saude

# Relatório de saúde (JSON para dashboard/API)
sre-toolkit saude -j | jq .

# Análise de disco (últimos 30 dias)
sre-toolkit disco --dir /var/log --dias 30

# Limpeza de disco (dry-run primeiro!)
sre-toolkit disco --dir /tmp --dias 7 -n
sre-toolkit disco --dir /tmp --dias 7 --limpeza

# Backup rotativo (mantém 7 backups)
sre-toolkit backup -r 7 /var/www /backups

# Healthcheck de serviços e endpoints
sre-toolkit health -s servicos.txt -e endpoints.txt

# Healthcheck com JSON
sre-toolkit health -j -t 5 https://api.exemplo.com/health

# Análise de logs nginx
sre-toolkit logs -f nginx /var/log/nginx/access.log

# Análise de logs JSON
sre-toolkit logs -f json -j /var/log/app.json.log | jq .

# Inventário AWS
sre-toolkit aws -t ec2 -r us-east-1

# Coleta de incidente (básica)
sre-toolkit incidente --dir /tmp/incidente-$(date +%F)

# Coleta de incidente (completa)
sre-toolkit incidente --coleta-completa --dir /tmp/incidente-$(date +%F-%H%M%S)
```

## Exemplos Avançados

### Monitoramento Contínuo com Systemd Timer
```bash
# Copiar templates
sudo cp sre-toolkit/systemd/sre-toolkit-health.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now sre-toolkit-health.timer
# Roda a cada 5 minutos com jitter aleatório
```

### Pipeline de Monitoramento Completo
```bash
# O exercício 10 implementa isso:
# healthcheck -> incidente se falha -> logs -> disco -> alerta -> relatório JSON
bash exercicios/gabarito/monitoramento-completo.sh -j > relatorio.json
```

### Automação de Backup com Retenção
```bash
# Adicionar ao crontab ou systemd timer
0 2 * * * sre-toolkit backup -r 14 /dados /backup >> /var/log/backup.log 2>&1
```

### Healthcheck com Alerta Automático
```bash
#!/usr/bin/env bash
# healthcheck-com-alerta.sh
sre-toolkit health -j https://api.exemplo.com/health || {
    sre-toolkit incidente --coleta-completa --dir /tmp/incidente-$(date +%F-%H%M%S)
    # O incidente.sh já tenta enviar alerta se ALERT_WEBHOOK_URL configurado
}
```

## Desenvolvimento: Adicionando Novos Subcomandos

```bash
# 1. Copiar template
cp sre-toolkit/comandos/saude.sh sre-toolkit/comandos/meu-comando.sh

# 2. Editar o script:
#    - Atualizar usage()
#    - Implementar main() com parse de argumentos
#    - Usar bibliotecas: source "${LIB_DIR}/log.sh" etc.
#    - Seguir padrão: JSON_OUTPUT, VERBOSE, DRY_RUN
#    - Retornar códigos de saída padronizados

# 3. Registrar no bin/sre-toolkit (array SUBCOMANDOS)
#    [meu-comando]="${COMANDOS_DIR}/meu-comando.sh"

# 4. Testar
sre-toolkit meu-comando --help
sre-toolkit meu-comando -j | jq .
```

### Padrão Obrigatório para Subcomandos
```bash
#!/usr/bin/env bash
# comandos/meu-comando.sh - Descrição curta
#
# Uso: sre-toolkit meu-comando [opções]

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"

JSON_OUTPUT=0
VERBOSE=0
DRY_RUN=0

usage() {
    cat <<EOF
meu-comando - Descrição

Uso: sre-toolkit meu-comando [opções]

Opções:
  -j, --json       Saída JSON
  -v, --verbose    Verboso
  -n, --dry-run    Simula
  -h, --help       Ajuda
EOF
}

main() {
    # Parse de argumentos
    # Validações
    # Lógica principal
    # Saída (JSON ou texto)
}

main "$@"
```

## Testes

```bash
# Verificar sintaxe
bash -n sre-toolkit/bin/sre-toolkit
bash -n sre-toolkit/comandos/*.sh

# ShellCheck
shellcheck sre-toolkit/bin/sre-toolkit sre-toolkit/comandos/*.sh sre-toolkit/lib/*.sh

# BATS (quando implementados)
bats sre-toolkit/testes/*.bats
```

## Exercícios

Veja [`exercicios/README.md`](exercicios/README.md) para 10 exercícios progressivos:

1. **Análise da Arquitetura** - Entender estrutura e fluxo
2. **Instalação e Configuração** - Setup local e config de alertas
3. **Subcomando `saude`** - Relatórios, JSON, script de monitoramento
4. **Subcomando `disco`** - Análise, limpeza, dry-run
5. **Subcomando `backup`** - Backup rotativo, retenção, integridade
6. **Subcomando `health`** - Healthchecks, loop com incidente
7. **Subcomando `logs`** - Análise nginx, JSON, formatos
8. **Subcomando `incidente`** - Coleta básica e completa
9. **Extensão: `docker`** - Novo subcomando para containers
10. **Integração Completa** - Pipeline orquestrado

Gabaritos em [`exercicios/gabarito/`](exercicios/gabarito/).

## Requisitos

- Bash 4.4+
- `jq` (JSON processing)
- `curl` (HTTP requests, alertas)
- `systemd` (para timers, healthcheck de serviços)
- `docker` (opcional, para subcomando docker)
- `aws cli v2` (opcional, para subcomando aws)
- `tar`, `gzip`, `sha256sum` (backup, incidente)

## Próximos Passos

- [ ] Adicionar testes BATS para todos os subcomandos
- [ ] Implementar subcomando `k8s` (Kubernetes)
- [ ] Adicionar métricas Prometheus (`/metrics` endpoint)
- [ ] Criar pacote `.deb`/`.rpm` para distribuição
- [ ] Documentação em MkDocs/GitHub Pages

## Referências

- [Módulo 10: Scripts de Produção](../10-scripts-de-producao/) - Padrões de robustez
- [Módulo 11: Admin de Servidores](../11-administracao-de-servidores/) - Backup, saúde
- [Módulo 12: Agendamento](../12-agendamento-e-servicos/) - Systemd timers
- [Módulo 13: Observabilidade](../13-observabilidade/) - Healthchecks, logs, alertas
- [Módulo 14: AWS CLI, jq, Terraform](../14-aws-cli-jq-terraform/) - Cloud automation
- [Template de script](../templates/script-producao.sh) - Padrão de cabeçalho

---

*Este módulo consolida todo o curso. Use o sre-toolkit como base para suas automações reais.*