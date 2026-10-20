# Rubrica: Módulo 05 — Laços (Lab: retry-curl.sh)

**Total:** 25 pts | **Aprovação:** 18/25 (72%)

---

## Critérios de Avaliação

| Critério | Peso | Exemplar (5) | Proficiente (4) | Em Desenvolvimento (3) | Inicial (1-2) |
|----------|------|--------------|-----------------|------------------------|---------------|
| **1. Strict Mode + ShellCheck** | 5 pts | `set -Eeuo pipefail`; zero warnings | Strict mode; ≤2 warnings | Strict mode incompleto; 3-5 warnings | Sem strict mode ou >5 warnings |
| **2. Parse de Flags (getopts)** | 3 pts | `getopts t:T:vnh`; `OPTARG` validado; `shift $((OPTIND-1))` | Flags funcionam; validação básica | Flags parciais; sem validação | Parse manual ou quebrado |
| **3. Validação de Entrada** | 3 pts | URL regex; max_tentativas >0; timeout >0 | Valida URL e números | Valida só números | Sem validação |
| **4. Retry Loop + Backoff** | 5 pts | Loop correto; backoff exponencial (1,2,4,8,16... teto 30s); break em sucesso | Loop funciona; backoff linear ou exponencial sem teto | Loop com bug (off-by-one, break errado) | Loop infinito ou sem backoff |
| **5. HTTP Request Robusto** | 3 pts | `curl -sf --max-time --connect-timeout -w "%{http_code}"`; captura código | curl funcional; timeout básico | curl sem timeout ou sem captura código | curl quebrado |
| **6. Logging Estruturado** | 3 pts | Timestamp, nível, tentativa, código HTTP; verbose condicional | Log básico com tentativa e código | Log mínimo | Sem log |
| **7. Dry-run Funcional** | 3 pts | `-n` simula sem curl; logs mostram `[DRY-RUN]` | Dry-run básico funciona | Dry-run parcial | Sem dry-run |

---

## Checklist de Entrega Obrigatória

- [ ] `shellcheck retry-curl.sh` → **zero warnings**
- [ ] `bash -n retry-curl.sh` → syntax OK
- [ ] `./retry-curl.sh -h` → help completo
- [ ] `./retry-curl.sh -n https://httpbin.org/get` → dry-run log
- [ ] `./retry-curl.sh https://httpbin.org/status/200` → sucesso HTTP 200
- [ ] `./retry-curl.sh -t 2 https://httpbin.org/status/500` → falha após 2 tentativas
- [ ] `./retry-curl.sh -v https://httpbin.org/get` → verbose mostra headers
- [ ] Backoff: 1s, 2s, 4s... (verificar logs)
- [ ] Código de saída: 0 sucesso, 1 falha, 2 uso inválido

---

## Critério de Aprovação Final

| Nota | Resultado | Ação |
|------|-----------|------|
| 23-25 | **Avançado** | Pronto para Módulo 06; pode mentorar |
| 18-22 | **Aprovado** | Pronto para Módulo 06 |
| 13-17 | **Revisão** | Refazer lab focando critérios <3 |
| <13 | **Reprovado** | Releia Módulo 05; agende mentoria |

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