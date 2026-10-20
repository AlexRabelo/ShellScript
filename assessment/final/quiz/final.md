# Quiz Final: Projeto Integrador (Módulo 15 — SRE Toolkit)

**Tempo:** 15 min | **Pontuação:** 15 pts | **Passe:** 10/15

---

## 1. Arquitetura CLI (1 pt)
Como o `sre-toolkit` despacha subcomandos?

- [ ] `case $1 in` direto no binário principal
- [ ] Array associativo `SUBCOMANDOS["saude"]="comandos/saude.sh"` + `source`
- [ ] `if/elif` chain para cada subcomando
- [ ] `exec` direto para script correspondente

---

## 2. Bibliotecas compartilhadas (1 pt)
Qual a ordem correta de `source` no subcomando?

- [ ] `source log.sh` → `source valida.sh` → `source util.sh`
- [ ] Qualquer ordem, são independentes
- [ ] `source util.sh` primeiro (define `LIB_DIR`)
- [ ] `source alerta.sh` antes de `log.sh`

---

## 3. Configuração externa (1 pt)
Onde o `sre-toolkit` busca o arquivo de configuração (prioridade)?

- [ ] 1. `$CONFIG_FILE` 2. `~/.config/sre-toolkit.conf` 3. `/etc/sre-toolkit/sre-toolkit.conf`
- [ ] 1. `/etc/sre-toolkit/sre-toolkit.conf` 2. `~/.config/sre-toolkit.conf`
- [ ] Apenas `/etc/sre-toolkit/sre-toolkit.conf`
- [ ] Apenas variáveis de ambiente

---

## 4. Dry-run transversal (1 pt)
Como o dry-run funciona em todos os subcomandos?

- [ ] Cada subcomando implementa seu próprio `if (( DRY_RUN ))`
- [ ] Função `run()` em `lib/util.sh` que todos usam
- [ ] Flag global `DRY_RUN=1` verificada no `bin/sre-toolkit`
- [ ] Subcomando `dry-run` separado

---

## 5. Alertas multi-canal (1 pt)
Qual biblioteca gerencia alertas?

- [ ] `lib/log.sh`
- [ ] `lib/alerta.sh`
- [ ] `lib/util.sh`
- [ ] `lib/valida.sh`

---

## 6. Saída JSON padronizada (1 pt)
Como os subcomandos emitem JSON?

- [ ] Cada um monta seu JSON com `echo`
- [ ] Função `json_output()` em `lib/util.sh`
- [ ] Variável `JSON_OUTPUT=1` + `jq -n` no final de cada `main()`
- [ ] `lib/valida.sh` tem `to_json()`

---

## 7. Systemd timer com jitter (1 pt)
No template `sre-toolkit-health.timer`, qual diretiva evita *thundering herd*?

- [ ] `OnCalendar=*-*-* *:*:00`
- [ ] `Persistent=true`
- [ ] `RandomizedDelaySec=30min`
- [ ] `AccuracySec=1min`

---

## 8. Healthcheck composto (1 pt)
O subcomando `health` verifica:

- [ ] Apenas systemd services
- [ ] Apenas HTTP endpoints
- [ ] **Systemd + HTTP/TCP + custom command** (configurável)
- [ ] Apenas portas TCP

---

## 9. Coleta de incidente (1 pt)
O que `incidente --coleta-completa` inclui?

- [ ] Apenas logs de systemd
- [ ] **Saúde, disco, rede, processos, logs, config, hardware, kernel**
- [ ] Apenas `dmesg` e `journalctl`
- [ ] Apenas arquivos em `/var/log`

---

## 10. Extensibilidade (1 pt)
Para adicionar subcomando `k8s`:

1. Copia `comandos/saude.sh` → `comandos/k8s.sh`
2. Implementa `usage()`, `main()`, usa `source "${LIB_DIR}/log.sh"` etc.
3. Registra no `bin/sre-toolkit` no array `SUBCOMANDOS`
4. Testa com `sre-toolkit k8s --help`

**O que FALTA nessa lista?**

- [ ] Adicionar testes BATS em `testes/k8s.bats`
- [ ] Atualizar `Makefile` para instalar
- [ ] Documentar no `README.md` do toolkit
- [ ] Todas as anteriores

---

## 11. Lock em backup (1 pt)
O subcomando `backup` usa `flock` para evitar concorrência. Onde está o lock file?

- [ ] `/tmp/backup.lock`
- [ ] `/var/lock/sre-toolkit-backup.lock`
- [ ] Configurável via `BACKUP_LOCK_FILE` no config
- [ ] Não usa lock (confia no systemd)

---

## 12. Log rotation (1 pt)
Como o `logs` subcomando lida com arquivos grandes?

- [ ] Lê tudo em memória com `mapfile`
- [ ] Processa linha a linha com `while IFS= read -r`
- [ ] Usa `awk` direto no arquivo
- [ ] Copia para `/tmp` primeiro

---

## 13. AWS inventory (1 pt)
O subcomando `aws` usa `jq` para processar JSON da AWS CLI. Qual pattern extrai IPs de instâncias EC2?

- [ ] `.Reservations[].Instances[].PublicIpAddress`
- [ ] `.Instances[].PublicIpAddress`
- [ ] `.Instances[].NetworkInterfaces[].PrivateIpAddresses[].PrivateIpAddress`
- [ ] Todas anteriores dependem do output

---

## 14. Testes BATS (1 pt)
Qual a estrutura de um teste BATS para subcomando?

```bats
@test "saude --json emits valid JSON" {
    run sre-toolkit saude -j
    [ "$status" -eq 0 ]
    echo "$output" | jq -e . >/dev/null
}
```

O que `run` faz?

- [ ] Executa comando e captura `$output`, `$status`, `$lines`
- [ ] Só executa, não captura nada
- [ ] Executa em subshell isolado
- [ ] Faz mock do comando

---

## 15. Troubleshooting (1 pt)
Subcomando `saude` retorna exit code 1 mas sem output no console. Onde investigar?

- [ ] `journalctl -u sre-toolkit-health`
- [ ] `$LOG_FILE` definido no config (padrão `/var/log/sre-toolkit.log`)
- [ ] `systemctl status sre-toolkit-health.timer`
- [ ] Todas anteriores

---

## Gabarito
1. B | 2. A | 3. A | 4. B | 5. B | 6. C | 7. C | 8. C | 9. B | 10. D | 11. B | 12. B | 13. A | 14. A | 15. D

---

## Critério de Avaliação
- **13-15:** Pronto para usar/estender SRE Toolkit em produção
- **10-12:** Revisar arquitetura (lib/*, bin/*, systemd/)
- **<10:** Refazer Módulo 15; foque em fluxo bin→lib→comandos