# sre-toolkit - Toolkit SRE Completo

Um toolkit de linha de comando para automação de infraestrutura SRE/Sysadmin, integrando funcionalidades dos módulos 10-14.

## Características

- 📊 **saude**: Relatório de saúde do servidor (CPU, RAM, disco, processos)
- 💾 **disco**: Análise e limpeza inteligente de disco
- ☁️ **backup**: Backup rotativo com verificação de integridade
- ❤️ **health**: Healthcheck de serviços e endpoints HTTP/TCP
- 📋 **logs**: Análise de logs (nginx, app, syslog) com métricas
- ☁️ **aws**: Inventário e análise de recursos AWS
- 🚨 **incidente**: Coleta de diagnóstico para troubleshooting
- 🔔 **Alertas**: Integração com Slack, Teams, Telegram, Webhook, Email
- 🐳 **Dry-run**: Simula execuções sem alterar nada
- 📝 **Logging**: Logs centralizados no journal/syslog
- 🔒 **Segurança**: Sandboxing, usuários não-root, capabilities limitadas

## Instalação

```bash
# Clonar repositório
git clone https://github.com/seu-usuario/sre-toolkit.git
cd sre-toolkit

# Instalar
sudo make install

# Ou instalar manualmente
sudo cp bin/sre-toolkit /usr/local/sbin/
sudo cp -r lib/ /usr/local/sre-toolkit/
sudo cp -r comandos/ /usr/local/sre-toolkit/
sudo mkdir -p /etc/sre-toolkit
sudo cp config/sre-toolkit.conf.example /etc/sre-toolkit/sre-toolkit.conf
sudo chmod 600 /etc/sre-toolkit/sre-toolkit.conf

# Configurar alertas (opcional)
sudo vim /etc/sre-toolkit/sre-toolkit.conf
```

## Uso Básico

```bash
# Ver saúde do servidor
sre-toolkit saude

# Ver saúde em formato JSON
sre-toolkit saude -j | jq .

# Analisar disco
sre-toolkit disco --dir /var/log

# Fazer backup
sre-toolkit backup /dados /backup -r 7

# Verificar saúde de serviços
sre-toolkit health -j https://api.exemplo.com/health

# Analisar logs
sre-toolkit logs /var/log/nginx/access.log -f nginx

# Inventário AWS
sre-toolkit aws -t ec2 -r us-east-1

# Coletar diagnóstico de incidente
sre-toolkit incidente --coleta-completa
```

## Configuração

Edite `/etc/sre-toolkit/sre-toolkit.conf` para configurar:

- **Alertas**: URLs do Slack, Teams, Telegram, Webhook
- **Backup**: Retenção padrão em dias
- **AWS**: Região e perfil padrão
- **Logs**: Caminho do arquivo de log

## Exemplos Avançados

```bash
# Saúde com JSON para dashboard
sre-toolkit saude -j > /var/lib/sre-toolkit/saude.json

# Backup com retenção customizada
sre-toolkit backup -r 14 /var/www /backups/www

# Healthcheck com alerta automático em caso de falha
sre-toolkit health -t 5 https://api.exemplo.com/health || \
  sre-toolkit incidente --coleta-completa --dir /tmp/incidente-$(date +%F)

# Análise de logs com output para ELK
sre-toolkit logs /var/log/app.json.log -f json -j > /var/log/logstash/input.log

# AWS inventory para relatório mensal
sre-toolkit aws -j -t all > /var/reports/aws-inventory-$(date +%Y%m).json
```

## Integração com Systemd

Os comandos podem ser agendados com systemd timers:

```bash
# Exemplo: healthcheck a cada 5 minutos
# /etc/systemd/system/sre-toolkit-health.timer
[Unit]
Description=Healthcheck a cada 5 minutos

[Timer]
OnCalendar=*:0/5
Persistent=true
RandomizedDelaySec=30s

[Install]
WantedBy=timers.target

# /etc/systemd/system/sre-toolkit-health.service
[Unit]
Description=Healthcheck dos serviços críticos
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/sre-toolkit health -j https://api.exemplo.com/health
StandardOutput=journal
StandardError=journal
```

## Desenvolvimento

Para contribuir ou desenvolver novos subcomandos:

```bash
# Criar novo subcomando
cp comandos/saude.sh comandos/meu-comando.sh
# Editar o script
# Testar: sre-toolkit meu-comando
```

## Licença

MIT License - veja o arquivo LICENSE para detalhes.