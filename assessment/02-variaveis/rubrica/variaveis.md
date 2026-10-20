# Rubrica: Módulo 02 — Variáveis e Parâmetros

**Total:** 20 pts | **Aprovação:** 14/20 (70%)

---

## Critérios de Avaliação

| Critério | Peso | Exemplar (4) | Proficiente (3) | Em Desenvolvimento (2) | Inicial (1) |
|----------|------|--------------|-----------------|------------------------|-------------|
| **1. Sintaxe e Boas Práticas** | 4 pts | Zero avisos ShellCheck; `set -euo pipefail`; shebang correto | ≤2 avisos menores; strict mode presente | 3-5 avisos; strict mode incompleto | >5 avisos ou sem strict mode |
| **2. Validação de Entrada** | 4 pts | Valida ambiente (lista permitida), args obrigatórios, flags | Valida ambiente e args obrigatórios | Valida só args obrigatórios | Sem validação ou validação quebrada |
| **3. Uso de Arrays Associativos** | 3 pts | `declare -A` correto; iteração `"${!arr[@]}"`; acesso por chave | `declare -A` correto; acesso por chave funciona | Array associativo declarado mas uso incorreto | Não usa array associativo |
| **4. Expansões de Parâmetro** | 3 pts | Usa `${var:-default}`, `${var:=default}`, `${var#pat}` corretamente | Usa pelo menos 2 expansões corretas | Usa 1 expansão correta | Não usa expansões ou usa errado |
| **4. Escopo e `local`** | 3 pts | **Todas** variáveis de função são `local`; sem vazamento | Maioria das variáveis `local`; 1 vazamento | Algumas `local`; múltiplos vazamentos | Sem `local`; variáveis globais modificadas |
| **6. Parse de Flags (getopts)** | 3 pts | `getopts` com `:a:vn`; `OPTARG` usado; `shift $((OPTIND-1))` | `getopts` funcional; flags obrigatórias tratadas | `getopts` presente mas incompleto | Parse manual ou `getopts` quebrado |
| **7. Legibilidade e Comentários** | 3 pts | Código autoexplicativo; comentários em "porquê"; funções pequenas | Comentários principais; funções organizadas | Comentários esparsos; funções longas | Sem comentários; spaghetti code |

---

## Checklist de Entrega Obrigatória

- [ ] Script executa sem erros: `bash script.sh -a prod web01`
- [ ] `shellcheck script.sh` → **zero warnings**
- [ ] `bash -n script.sh` → syntax OK
- [ ] Help funciona: `script.sh -h`
- [ ] Dry-run funciona: `script.sh -n -a dev srv1`
- [ ] Verbose funciona: `script.sh -v -a prod srv1`
- [ ] Erro claro se ambiente inválido: `script.sh -a staging srv1`
- [ ] Erro claro se sem servidores: `script.sh -a prod`
- [ ] Array associativo com IPs por ambiente (dev/prod/homolog)
- [ ] Iteração correta sobre servidores com `"${SERVIDORES[@]}"`

---

## Critério de Aprovação Final

| Nota | Resultado | Ação |
|------|-----------|------|
| 18-20 | **Avançado** | Pronto para próximo módulo; pode mentorar pares |
| 14-17 | **Aprovado** | Pronto para próximo módulo |
| 10-13 | **Revisão** | Refazer lab focando nos critérios <3 |
| <10 | **Reprovado** | Releia módulo; agende mentoria 1:1 |

---

## Feedback Qualitativo (preencher pelo avaliador)

**Pontos fortes:**
- 

**Pontos de melhoria:**
- 

**Conceitos para revisar:**
- 

**Próximos passos sugeridos:**
-