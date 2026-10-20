# Exemplos de Systemd Timers

## 1. Timer Diário Simples (backup-diario.timer)
```ini
[Timer]
OnCalendar=daily 02:30
Persistent=true
RandomizedDelaySec=15min
AccuracySec=1min
```
- Executa todo dia às 02:30
- Se desligado no horário, roda no boot seguinte
- Jitter de até 15min

## 2. Timer Horário (ex: healthcheck a cada hora)
```ini
[Timer]
OnCalendar=hourly
Persistent=true
RandomizedDelaySec=5min
```
- Executa no minuto 0 de cada hora
- Útil para healthchecks frequentes

## 3. Timer Semanal (ex: limpeza semanal domingos 03:00)
```ini
[Timer]
OnCalendar=Sun 03:00
Persistent=true
RandomizedDelaySec=30min
```

## 4. Timer Mensal (ex: rotação de logs dia 1 às 04:00)
```ini
[Timer]
OnCalendar=*-*-01 04:00
Persistent=true
```

## 5. Timer no Boot (ex: script de inicialização)
```ini
[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=false
```
- Executa 5min após boot
- Repete a cada 1h enquanto sistema ligado

## 6. Timer com Múltiplos Horários (ex: backup 2x/dia)
```ini
[Timer]
OnCalendar=02:30
OnCalendar=14:30
Persistent=true
RandomizedDelaySec=10min
```

## 7. Timer com Intervalos Relativos
```ini
[Timer]
OnUnitActiveSec=30min
OnUnitInactiveSec=5min
Persistent=false
```
- Repete 30min após término da execução anterior
- Se falhar, tenta novamente em 5min

## 8. Timer para Execução Única (run-once)
```ini
[Timer]
OnActiveSec=10s
Persistent=false
```
- Executa 10s após timer ser ativado (systemctl start timer)
- Não repete

---

## Sintaxe OnCalendar (systemd.time)

| Formato | Significado |
|---------|-------------|
| `daily` | Todo dia à meia-noite |
| `daily HH:MM` | Todo dia no horário |
| `weekly` | Domingos à meia-noite |
| `weekly HH:MM` | Domingos no horário |
| `monthly` | Dia 1 à meia-noite |
| `monthly HH:MM` | Dia 1 no horário |
| `yearly` | 1 Jan à meia-noite |
| `*-*-* HH:MM:SS` | Todo dia no horário exato |
| `Mon *-*-* HH:MM` | Segundas no horário |
| `Mon,Tue,Wed *-*-* HH:MM` | Seg-Ter-Qua no horário |
| `*-*-01 HH:MM` | Dia 1 de cada mês |
| `*-01,07-01 HH:MM` | Dia 1 de Jan e Jul |
| `Sat,Sun *-*-* HH:MM` | Finais de semana |

---

## Comandos Úteis

```bash
# Instalar (copiar para /etc/systemd/system/)
sudo cp backup-diario.service backup-diario.timer /etc/systemd/system/
sudo systemctl daemon-reload

# Habilitar e iniciar timer
sudo systemctl enable --now backup-diario.timer

# Ver status
systemctl status backup-diario.timer
systemctl list-timers --all

# Ver próximas execuções
systemctl list-timers --all | grep backup

# Ver logs do serviço
journalctl -u backup-diario.service -f
journalctl -u backup-diario.service -n 50

# Ver logs do timer
journalctl -u backup-diario.timer -f

# Forçar execução imediata
sudo systemctl start backup-diario.service

# Parar timer (cancela próximas execuções)
sudo systemctl stop backup-diario.timer

# Desabilitar timer
sudo systemctl disable --now backup-diario.timer

# Ver detalhes do timer
systemctl show backup-diario.timer --property=NextElapseUSecMonotonic,LastTriggerUSecMonotonic
```