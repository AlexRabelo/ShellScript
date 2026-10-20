# 12-agendamento-e-servicos

## Objetivo
Migrar agendamentos de **cron para systemd timers** com hardening, persistência, jitter e observabilidade. Criar services oneshot/type=simple seguros e monitoráveis.

## Analogia
> **Cron = despertador analógico.** Toca na hora, não sabe se você acordou, não tem snooze inteligente, não avisa se falhou.
> **Systemd timer = assistente pessoal.** Sabe se você está dormindo (persistência), acorda com delay aleatório (jitter), avisa se você não levantou (failure tracking), integra com seu calendário (journal, Prometheus).

## Conceitos-chave

| Conceito | Cron | Systemd Timer |
|----------|------|---------------|
| Sintaxe | `* * * * *` | `OnCalendar=*-*-* 02:30:00` |
| Persistência (rodar no boot se perdeu) | ❌ | ✅ `Persistent=true` |
| Jitter (evita thundering herd) | ❌ | ✅ `RandomizedDelaySec` |
| Logs centralizados | Arquivos dispersos | ✅ Journal (`journalctl -u timer`) |
| Dependências (rede, discos) | Manual no script | ✅ `After=`, `Wants=`, `ConditionPathIsMountPoint` |
| Sandbox/Hardening | ❌ | ✅ `PrivateTmp`, `ProtectSystem`, `NoNewPrivileges` |
| Monitoramento | `grep /var/log/cron` | ✅ `systemctl list-timers`, `systemctl is-failed` |

## Exemplos

| Arquivo | Descrição |
|---------|-----------|
| [`cron-para-systemd.sh`](exemplos/cron-para-systemd.sh) | Script que lê crontab e gera units `.service` + `.timer` equivalentes |
| [`gerencia-timers.sh`](exemplos/gerencia-timers.sh) | CLI para listar, habilitar, desabilitar, ver próxima execução, status de falha |
| [`backup-diario.service`](exemplos/backup-diario.service) | Service oneshot com sandbox completo para backup |
| [`backup-diario.timer`](exemplos/backup-diario.timer) | Timer diário 02:30 com `Persistent=true`, `RandomizedDelaySec=30min` |
| [`timers-exemplos.md`](exemplos/timers-exemplos.md) | Referência rápida: `OnCalendar`, `AccuracySec`, `Persistent`, etc. |

## Exercícios

Veja [`exercicios/README.md`](exercicios/README.md) para 5 exercícios:

1. **Timer para healthcheck** - `healthcheck-periodico.service` + `.timer` (5 min, persist, jitter, sandbox)
2. **Migração cron → systemd** - 5 pares service+timer a partir de crontab real
3. **Timer condicional** - `backup-condicional.service` + `.timer` (rede, mountpoint, disco >90%, sentinela)
4. **Monitoramento de timers** - `monitora-timers.sh` (JSON para Prometheus/Grafana, alerta se falha)
5. **ShellCheck: compara agendamento** - `compara-agendamento-corrigido.sh`

Gabarito em [`exercicios/gabarito/`](exercicios/gabarito/) — inclui 10 unit files prontos.

## Armadilhas Comuns

| Armadilha | Sintoma | Solução |
|-----------|---------|---------|
| `systemctl start timer` não roda o service | Timer só agenda, não executa | Use `systemctl start servico.service` para testar |
| `OnCalendar=*-*-* 02:30` não roda no boot se estava desligado | Execução perdida | `Persistent=true` no `.timer` |
| Thundering herd em frota | 500 servidores rodam backup às 02:00:00 | `RandomizedDelaySec=30min` (ou 1h) |
| Service falha mas timer continua "active" | Falha silenciosa | `systemctl is-failed servico.service` no monitoramento |
| Sandbox quebra script que precisa ler `/etc` | `Permission denied` | `ReadOnlyPaths=/etc`, `ReadWritePaths=/etc/meu-app` |
| `ExecStart` com pipe/`&&` | systemd não expande shell | Use `ExecStart=/bin/bash -c 'cmd1 | cmd2'` ou script wrapper |

## Referências

- `man systemd.timer` / `man systemd.service` / `man systemd.time`
- `systemd-analyze verify /caminho/unit`
- `systemctl show timer --property=NextElapseUSecMonotonic,LastTriggerUSecMonotonic`
- [systemd timer calendar spec](https://www.freedesktop.org/software/systemd/man/systemd.time.html#Calendar%20Events)
- [Hardening systemd services](https://systemd.io/SECURITY_HARDENING/)

## Próximos Passos

Módulo 13: **Observabilidade** — Healthchecks compostos, análise de logs estruturados, alertas webhook, métricas Prometheus, dashboards HTML.