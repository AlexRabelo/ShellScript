# Rubrica: Módulo 08 — Processamento de Texto (Lab: relatorio-access.sh)

**Total:** 25 pts | **Aprovação:** 18/25 (72%)

---

## Critérios de Avaliação

| Critério | Peso | Exemplar (5) | Proficiente (4) | Em Desenvolvimento (3) | Inicial (1-2) |
|----------|------|--------------|-----------------|------------------------|---------------|
| **1. Strict Mode + ShellCheck** | 5 pts | `set -Eeuo pipefail`; zero warnings | Strict mode; ≤2 warnings | Strict mode incompleto; 3-5 warnings | Sem strict mode ou >5 warnings |
| **2. Parse de Flags + JSON** | 3 pts | `getopts jh`; `-j` emite JSON válido com `jq -n` | Flags funcionam; JSON básico | Flags parciais; JSON inválido | Parse manual ou sem JSON |
| **3. Pipeline grep|sed|awk** | 5 pts | Cada função usa ferramenta certa; pipeline eficiente | Pipeline funcional | Pipeline com ferramenta errada | Sem pipeline; tudo em bash |
| **4. awk Avançado** | 5 pts | Arrays associativos (IP count, bytes sum); BEGIN/END; NR/NF | Arrays básicos; NR/NF | awk só print $1 | awk quebrado |
| **5. Extração de Timestamp** | 3 pts | Extrai hora do campo 4 `[15/Jan/2024:10:00:01]` corretamente | Extrai hora com regex | Extração parcial | Não extrai |
| **6. Saída JSON Estruturada** | 3 pts | `jq -n` com todos campos; válido | JSON básico | JSON manual (strings) | Sem JSON |
| **7. Validação + Help** | 3 pts | Valida arquivo legível; help completo | Valida arquivo; help básico | Help apenas | Sem validação |

---

## Checklist de Entrega Obrigatória

- [ ] `shellcheck relatorio-access.sh` → **zero warnings**
- [ ] `bash -n relatorio-access.sh` → syntax OK
- [ ] `./relatorio-access.sh -h` → help
- [ ] `./relatorio-access.sh access.log` → saída texto completa
- [ ] `./relatorio-access.sh -j access.log | jq .` → JSON válido
- [ ] Total requisições correto (NR)
- [ ] Top 5 IPs contagem + bytes (sort -nr | head -5)
- [ ] Códigos resposta ordenados
- [ ] Requisições por hora (0-23)

---

## Critério de Aprovação Final

| Nota | Resultado | Ação |
|------|-----------|------|
| 23-25 | **Avançado** | Pronto para Módulo 09 |
| 18-22 | **Aprovado** | Pronto para Módulo 09 |
| 13-17 | **Revisão** | Refazer lab focando awk/pipeline |
| <13 | **Reprovado** | Releia Módulo 08; agende mentoria |

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