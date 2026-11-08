# Exercícios - Módulo 12: Agendamento e Serviços (systemd timers + cron)

## Pré-requisitos
- Módulo 10 (template produção) e Módulo 11 (scripts admin) completos
- Entender systemd units: `.service`, `.timer`, `.target`
- Ter `systemd` rodando (VM, WSL2 com systemd, ou servidor)
- `jq` para JSON

---

## Exercício 1: Timer para Healthcheck Periódico

### Enunciado
Crie um timer systemd que execute o `healthcheck-servicos.sh` (Módulo 11) a cada 5 minutos, com:
- Persistência (roda no boot se perdeu execução)
- Jitter de 30 segundos
- Logs no journal
- Sandbox de segurança

### Arquivos a Criar
1. `healthcheck-periodico.service` - Serviço oneshot
2. `healthcheck-periodico.timer` - Timer a cada 5 min

### Requisitos do .service
- [ ] `Type=oneshot`
- [ ] `ExecStart` chama `healthcheck-servicos.sh -j` (JSON para parsing)
- [ ] `User=monitoring` (ou usuário dedicado)
- [ ] Sandbox: `PrivateTmp`, `ProtectSystem=strict`, `ProtectHome`, `NoNewPrivileges`, `CapabilityBoundingSet=`, `LockPersonality`, `MemoryDenyWriteExecute`, `RestrictAddressFamilies`, `RestrictNamespaces`, `RestrictRealtime`, `SystemCallFilter=@system-service`
- [ ] `ReadWritePaths` para arquivos de configuração (servicos.txt, endpoints.txt)
- [ ] `StandardOutput=journal`, `StandardError=journal`, `SyslogIdentifier=healthcheck-periodico`
- [ ] `TimeoutStartSec=60`
- [ ] `ConditionPathExists` para script e arquivos de config

### Requisitos do .timer
- [ ] `OnCalendar=*:0/5` (a cada 5 min)
- [ ] `Persistent=true`
- [ ] `RandomizedDelaySec=30s`
- [ ] `AccuracySec=1min`
- [ ] `Requires=healthcheck-periodico.service`
- [ ] `WantedBy=timers.target`

### Entregável
Dois arquivos unit + instruções de instalação/teste.

---

## Exercício 2: Migrar Cron para Systemd Timer

### Enunciado
O crontab abaixo roda em produção. Migre **completamente** para systemd timers mantendo o mesmo comportamento.

```bash
# /etc/crontab
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Backup diário 02:30
30 2 * * * backup /usr/local/sbin/backup-rotativo.sh -r 30 /dados /backup >> /var/log/backup.log 2>&1

# Limpeza logs hora em hora
0 * * * * backup /usr/local/sbin/limpa-logs.sh -d 7 /var/log/app >> /var/log/limpeza.log 2>&1

# Healthcheck a cada 10 min
*/10 * * * * nagios /usr/local/bin/healthcheck.sh >> /var/log/healthcheck.log 2>&1

# Relatório semanal segundas 06:00
0 6 * * 1 root /usr/local/sbin/relatorio-saude.sh -j > /var/log/saude-semanal.json 2>&1

# Script de boot
@reboot root /usr/local/sbin/startup-checks.sh >> /var/log/startup.log 2>&1
```

### Tarefa
Crie 5 pares `.service` + `.timer` (exceto @reboot que é só `.service`):
1. `backup-diario-migracao.service` + `.timer`
2. `limpeza-horaria-migracao.service` + `.timer`
3. `healthcheck-migracao.service` + `.timer`
4. `relatorio-semanal-migracao.service` + `.timer`
5. `startup-checks-migracao.service` (sem timer)

### Requisitos Comuns
- [ ] Usuário correto (backup, nagios, root)
- [ ] Sandbox apropriado para cada
- [ ] Logs via journal (não arquivos)
- [ ] `Persistent=true` onde faz sentido
- [ ] `RandomizedDelaySec` apropriado (evita thundering herd)
- [ ] `WorkingDirectory` se necessário
- [ ] `Environment` para variáveis (PATH, etc.)
- [ ] Documentação no `Description` e `Documentation=man:...`

### Entregável
10 arquivos (5 service + 5 timer) + `README-migracao.md` com instruções.

---

## Exercício 3: Timer com Dependências e Condições

### Enunciado
Crie um timer para `backup-rotativo-estendido.sh` (Módulo 11) que:
- Só roda se a rede estiver disponível (`network-online.target`)
- Só roda se o destino remoto estiver montado (ex: `/mnt/backup-remoto`)
- Não roda se o disco local estiver > 90% cheio
- Executa às 03:00 com jitter 20min
- Se falhar, systemd não reinicia automaticamente (Type=oneshot)

### Requisitos
- [ ] `After=network-online.target` + `Wants=network-online.target`
- [ ] `ConditionPathIsMountPoint=/mnt/backup-remoto`
- [ ] `ConditionPathExists=!/run/nobackup` (arquivo sentinela para desabilitar)
- [ ] `ExecStartPre` com script que verifica uso de disco (`df / | awk 'NR==2 {print $5}' | sed 's/%//'`) e falha se > 90
- [ ] `ExecStart` chama backup-rotativo-estendido.sh com `-R user@host:/path`
- [ ] Sandbox completo
- [ ] `TimeoutStartSec=7200` (2h para backup grande)

### Entregável
`backup-condicional.service` + `backup-condicional.timer`

---

## Exercício 4: Monitoramento de Timers (Script)

### Enunciado
Crie um script `monitora-timers.sh` que:
- Lista todos os timers ativos com próxima execução
- Verifica se algum timer falhou na última execução (`systemctl is-failed`)
- Gera relatório em JSON para ingestão em Prometheus/Grafana
- Opção `--alerta` que sai com código 1 se houver falhas

### Requisitos
- [ ] Usa `systemctl list-timers --all --no-pager --output=json` (systemd 255+)
- [ ] Ou parseia saída textual para compatibilidade
- [ ] Para cada timer: nome, próxima execução, última execução, serviço associado, status
- [ ] Verifica `systemctl is-failed servico.service` para cada
- [ ] Saída JSON: array de objetos com campos padronizados
- [ ] Opções: `-j/--json`, `-a/--alerta`, `-f/--falhas-apenas`
- [ ] Template de produção (modo estrito, trap, log)

### Exemplo Saída JSON
```json
{
  "timestamp": "2026-10-13T10:30:00-03:00",
  "timers": [
    {
      "timer": "backup-diario.timer",
      "service": "backup-diario.service",
      "proxima_execucao": "2026-10-14T02:30:00-03:00",
      "ultima_execucao": "2026-10-13T02:30:15-03:00",
      "ativo": true,
      "falhou_ultima": false,
      "ultimo_codigo_saida": 0
    }
  ]
}
```

### Entregável
`monitora-timers.sh` (executável, auto-documentado)

---

## Exercício 5: Cron vs Systemd - Análise Comparativa (ShellCheck)

### Enunciado
O script abaixo compara cron e systemd timers. Tem **7+ avisos ShellCheck**. Corrija todos.

```bash
#!/usr/bin/env bash
# compara-agendamento.sh

timers=$(systemctl list-timers --all --no-pager)
crons=$(cat /etc/crontab /etc/cron.d/* 2>/dev/null)

echo "Timers ativos:"
echo "$timers" | grep -v "^$" | wc -l

echo "Entradas cron:"
echo "$crons" | grep -v "^#" | grep -v "^$" | wc -l

for timer in $timers; do
  proximo=$(systemctl show $timer --property=NextElapseUSecMonotonic --value)
  echo "Timer: $timer, Próximo: $proximo"
done

if [ $# -eq 1 ]; then
  echo "Argumento: $1"
fi
```

### Avisos Esperados
- SC2086: aspas em expansões
- SC2046: comando substitution sem aspas
- SC2002: cat desnecessário
- SC2155: declaração/atribuição separadas
- SC2126: grep -c em vez de wc -l
- SC2034: variável não usada
- SC2162: read sem -r

### Entregável
`compara-agendamento-corrigido.sh` (zero avisos)

---

## Como Testar (em VM com systemd)

```bash
# 1. Copiar units para /etc/systemd/system/
sudo cp *.service *.timer /etc/systemd/system/
sudo systemctl daemon-reload

# 2. Habilitar e testar
sudo systemctl enable --now healthcheck-periodico.timer
systemctl status healthcheck-periodico.timer
systemctl start healthcheck-periodico.service
journalctl -u healthcheck-periodico.service -f

# 3. Verificar próximas execuções
systemctl list-timers --all | grep healthcheck

# 4. Testar monitoramento
./monitora-timers.sh -j | jq .
./monitora-timers.sh --alerta && echo "OK" || echo "ALERTA: timers falharam"
```

---

## Critérios de Avaliação

| Critério | Peso |
|----------|------|
| Units systemd corretas e seguras | 30% |
| Timers com OnCalendar/Persistent/RandomizedDelay | 20% |
| Sandbox e hardening apropriados | 15% |
| Script de monitoramento funcional + JSON | 15% |
| ShellCheck zero avisos | 10% |
| Documentação e auto-explicativo | 10% |

---

## Dicas

> **Teste units sem instalar:** `systemd-analyze verify /caminho/arquivo.service`

> **Debug timer:** `systemctl show timer --property=NextElapseUSecMonotonic,LastTriggerUSecMonotonic`

> **Forçar execução:** `systemctl start servico.service` (não start timer!)

> **Ver logs falhas:** `journalctl -u servico -p err..crit -n 50`

> **Desabilitar timer temporário:** `touch /run/nobackup` (ConditionPathExists=!)