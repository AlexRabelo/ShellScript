# Rubrica: Projeto Final — SRE Toolkit (Módulo 15)

**Total:** 50 pts | **Aprovação:** 35/50 (70%)

---

## Critérios de Avaliação

| Critério | Peso | Exemplar (5) | Proficiente (4) | Em Desenvolvimento (3) | Inicial (1-2) |
|----------|------|--------------|-----------------|------------------------|---------------|
| **1. Arquitetura CLI** | 5 pts | `bin/sre-toolkit` despacha via array associativo `SUBCOMANDOS`; source libs | Dispatch funcional | `case` ou `if/elif` | Monolito único |
| **2. Bibliotecas (lib/)** | 5 pts | `log.sh`, `util.sh`, `valida.sh`, `alerta.sh` independentes; `LIB_DIR` | Libs funcionais | Libs com dependência circular | Tudo inline |
| **3. Configuração Externa** | 3 pts | Prioridade: `$CONFIG_FILE` → `~/.config/...` → `/etc/...`; validação | Config funcional | Apenas 1 local | Sem config |
| **4. Dry-run Transversal** | 3 pts | `run()` em `lib/util.sh` usada por todos subcomandos | Dry-run por subcomando | Flag global sem função | Sem dry-run |
| **5. Alertas Multi-canal** | 3 pts | `lib/alerta.sh`: log + webhook + email; severidade | 2 canais | 1 canal | Sem alertas |
| **6. JSON Padronizado** | 3 pts | `json_output()` em `lib/util.sh`; `jq -n` | JSON funcional | `echo` manual | Sem JSON |
| **7. Systemd + Jitter** | 3 pts | Timer com `RandomizedDelaySec=30min`; `Persistent=true` | Timer básico | Timer sem jitter | Sem systemd |
| **8. Healthcheck Compose** | 3 pts | Systemd + HTTP/TCP + custom command (configurável) | 2 tipos | 1 tipo | Apenas systemd |
| **9. Incidente Coleta** | 3 pts | `--coleta-completa`: saúde, disco, rede, processos, logs, config, hw, kernel | 5+ categorias | 3 categorias | Apenas logs |
| **10. Extensibilidade** | 3 pts | Adicionar `k8s`: copiar template + implementar + registrar + testar + BATS + docs | 4/5 passos | 2-3 passos | <2 passos |
| **11. Lock Backup** | 3 pts | `flock` em `/var/lock/sre-toolkit-backup.lock` (configurável) | Lock funcional | Lock em /tmp | Sem lock |
| **12. Log Rotation** | 3 pts | `while IFS= read -r` streaming; não carrega tudo em memória | `awk` no arquivo | `mapfile` (memória) | Não lida grande |
| **13. AWS + jq** | 3 pts | Extrai IPs EC2 com `.Reservations[].Instances[].PublicIpAddress` | Query jq funcional | Query parcial | Sem jq |
| **14. Testes BATS** | 3 pts | Estrutura `@test` com `run` capturando `$output`, `$status`, `$lines` | Testes básicos | 1-2 testes | Sem testes |
| **15. Troubleshooting** | 3 pts | Sabe investigar: journalctl, `$LOG_FILE`, timer status | 2 fontes | 1 fonte | Não sabe |

---

## Checklist de Entrega Obrigatória

- [ ] `shellcheck bin/sre-toolkit lib/*.sh comandos/*.sh` → **zero warnings**
- [ ] `bash -n` em todos scripts → syntax OK
- [ ] `./sre-toolkit --help` → lista subcomandos
- [ ] `./sre-toolkit saude -j | jq .` → JSON válido
- [ ] `./sre-toolkit backup -n /etc /tmp/bkp` → dry-run
- [ ] `./sre-toolkit health --config test.conf` → healthcheck composto
- [ ] `./sre-toolkit incidente --coleta-completa` → tarball com 8 categorias
- [ ] `./sre-toolkit logs -f /var/log/syslog` → streaming (não carrega tudo)
- [ ] `./sre-toolkit aws -j` → JSON com IPs EC2
- [ ] `bats testes/` → todos passam
- [ ] `systemctl --user daemon-reload && systemctl --user start sre-toolkit-health.timer` → timer ativo
- [ ] `RandomizedDelaySec` verificado em `systemctl cat sre-toolkit-health.timer`

---

## Critério de Aprovação Final

| Nota | Resultado | Ação |
|------|-----------|------|
| 45-50 | **Expert SRE** | Pronto para produção; pode ensinar/mentorar |
| 35-44 | **Aprovado** | SRE Toolkit operacional; estenda para seu uso |
| 25-34 | **Revisão** | Foque nos critérios <3; reimplemente libs/comandos |
| <25 | **Reprovado** | Refazer Módulo 15 completo; agende mentoria |

---

## Feedback Qualitativo

**Pontos fortes:**
- 

**Pontos de melhoria:**
- 

**Conceitos para revisar:**
- 

**Próximos passos:**
-