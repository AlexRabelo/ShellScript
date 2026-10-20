# Systemd Timer para healthcheck - exemplos prontos para produção

Este diretório contém os arquivos para substituir o crontab por systemd timers.

## Estrutura

| Arquivo | Tipo | Timer | Serviço |
|---------|------|-------|---------|
| `healthcheck-periodico` | service | `healthcheck-periodico.timer` | `healthcheck-periodico.service` |
| `backup-diario-migracao` | service | `backup-diario-migracao.timer` | `backup-diario-migracao.service` |
| `limpeza-horaria-migracao` | service | `limpeza-horaria-migracao.timer` | `limpeza-horaria-migracao.service` |
| `healthcheck-migracao` | service | `healthcheck-migracao.timer` | `healthcheck-migracao.service` |
| `relatorio-semanal-migracao` | service | `relatorio-semanal-migracao.timer` | `relatorio-semanal-migracao.service` |
| `startup-checks-migracao` | service | - (não tem timer - @reboot) | `startup-checks-migracao.service` |

## Instalação

```bash
# Copiar para sistema
sudo ./install.sh

# Ou manualmente
sudo cp *.service *.timer /etc/systemd/system/

# Recarregar configuração
sudo systemctl daemon-reload

# Habilitar timers (não services diretamente)
sudo systemctl enable --now healthcheck-periodico.timer
sudo systemctl enable --now backup-diario-migracao.timer
sudo systemctl enable --now limpeza-horaria-migracao.timer
sudo systemctl enable --now healthcheck-migracao.timer
sudo systemctl enable --now relatorio-semanal-migracao.timer
sudo systemctl enable startup-checks-migracao.service  # @reboot equivalente
```

## Verificação

```bash
# Listar timers ativos
systemctl list-timers --all | grep migracao

# Verificar status de um timer
systemctl status healthcheck-periodico.timer

# Ver próximas execuções
systemctl show healthcheck-periodico.timer --property=NextElapseUSecMonotonic

# Ver logs
journalctl -u healthcheck-periodico.service -f

# Forçar execução manual
sudo systemctl start healthcheck-periodico.service
```

## Comparação: Cron -> Systemd

| Crontab | Systemd Timer |
|---------|---------------|
| `30 2 * * *` | `OnCalendar=daily 02:30` |
| `*/15 * * * *` | `OnCalendar=*:0/15` |
| `0 3 * * 0` | `OnCalendar=Sun 03:00` |
| `@reboot` | `.service` + `WantedBy=multi-user.target` (executa no boot) |

## Vantagens systemd timers

1. **Persistent=true**: Executa no próximo horário se sistema estava desligado
2. **RandomizedDelaySec**: Jitter automático para evitar thundering herd
3. **Logs centralizados**: `journalctl -u servico`
4. **Dependências**: `After=`, `Wants=`, `Before=`
5. **Sandbox**: ProtectSystem, PrivateTmp, CapabilityBoundingSet, etc.
6. **Monitoramento**: `systemctl status`, `systemctl list-timers`

## Desabilitação temporária

```bash
# Criar "sentinela" para impedir execução
sudo touch /run/nobackup

# O timer tem: ConditionPathExists=!/run/nobackup
# Assim, o serviço não executa enquanto o arquivo existir
```