# Rubrica: Módulo 10 — Scripts de Produção (Lab: backup-robusto.sh)

**Total:** 25 pts | **Aprovação:** 18/25 (72%)

---

## Critérios de Avaliação

| Critério | Peso | Exemplar (5) | Proficiente (4) | Em Desenvolvimento (3) | Inicial (1-2) |
|----------|------|--------------|-----------------|------------------------|---------------|
| **1. Strict Mode + ShellCheck** | 5 pts | `set -Eeuo pipefail`; zero warnings | Strict mode; ≤2 warnings | Strict mode incompleto; 3-5 warnings | Sem strict mode ou >5 warnings |
| **2. Validação de Args + Pré-reqs** | 3 pts | 2 args obrigatórios; origem existe; destino gravável; `command -v` tar/date/gzip | Valida args e pré-reqs básicos | Valida apenas args | Sem validação |
| **3. Flags + Dry-run + Verbose** | 3 pts | `getopts nvh`; `-n` simula sem executar; `-v` log detalhado | Flags funcionam | Flags parciais | Parse manual |
| **4. Logging Estruturado** | 3 pts | Timestamp ISO, nível (INFO/WARN/ERROR), PID, contexto | Log com timestamp e nível | Log básico | Sem log |
| **5. Trap + Limpeza** | 3 pts | `trap EXIT/ERR/INT/TERM`; `mktemp` + limpeza garantida | Trap EXIT + limpeza | Trap parcial | Sem trap |
| **6. Flock Anti-concorrência** | 3 pts | `flock -n` em `/var/lock/backup-robusto.lock` (persistente) | Lock funcional | Lock em /tmp | Sem lock |
| **7. Timestamp Único + Idempotência** | 3 pts | `%F-%H%M%S` evita meia-noite; rodar 2x não quebra | Timestamp único; idempotente | Timestamp básico | Timestamp só data |
| **8. Códigos de Saída** | 2 pts | 0=sucesso, 1=erro, 2=uso, 3=pré-req | Códigos básicos | Apenas 0/1 | Sem códigos |

---

## Checklist de Entrega Obrigatória

- [ ] `shellcheck backup-robusto.sh` → **zero warnings**
- [ ] `bash -n backup-robusto.sh` → syntax OK
- [ ] `./backup-robusto.sh -h` → help completo
- [ ] `./backup-robusto.sh -n /etc /tmp/teste-backup` → dry-run log
- [ ] `./backup-robusto.sh /etc /tmp/teste-backup` → cria backup com timestamp
- [ ] Rodar 2x seguida → idempotente (não falha, cria 2 arquivos)
- [ ] Concorrência: 2 terminais simultâneos → segundo falha com lock
- [ ] Código de saída: 0 sucesso, 1 erro, 2 uso, 3 pré-req
- [ ] Log em `/var/log/backup-robusto.log` (ou stdout se sem permissão)

---

## Critério de Aprovação Final

| Nota | Resultado | Ação |
|------|-----------|------|
| 23-25 | **Avançado** | Pronto para Módulo 11+; pode blindar scripts legados |
| 18-22 | **Aprovado** | Pronto para Módulo 11 |
| 13-17 | **Revisão** | Refazer lab focando trap/flock/dry-run |
| <13 | **Reprovado** | Releia Módulo 10; agende mentoria |

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