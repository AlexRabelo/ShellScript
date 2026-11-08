# Módulo 08: Processamento de Texto — grep, sed, awk

> **Analogia:** `grep` é o **filtro** (acha linhas). `sed` é o **editor de fluxo** (transforma linhas). `awk` é a **máquina de processamento** (colunas, cálculos, relatórios).

## Objetivos

Ao final deste módulo você será capaz de:

- Filtrar linhas com `grep` (básico, `-E`, `-P`, `-v`, `-i`, `-c`, `-n`, `-A/-B/-C`)
- Transformar texto com `sed` (substituição `s///`, deleção `d`, impressão `p`, endereços)
- Processar colunas e gerar relatórios com `awk` (`FS`, `OFS`, `NR`, `NF`, `BEGIN/END`, arrays)
- Combinar em pipelines eficientes
- Escolher a ferramenta certa para cada tarefa

---

## 1. grep — encontrar linhas

```bash
grep "erro" arquivo.log              # linhas com "erro"
grep -i "erro" arquivo.log           # case-insensitive
grep -v "sucesso" arquivo.log        # invertido (NÃO tem)
grep -c "erro" arquivo.log           # conta linhas
grep -n "erro" arquivo.log           # mostra número da linha
grep -E "erro|falha|fail" arquivo.log # regex estendida (OU)
grep -P "\d{4}-\d{2}-\d{2}" arquivo.log # regex Perl (PCRE)
grep -r "timeout" /etc/              # recursivo
grep -A 2 -B 1 "erro" arquivo.log    # 2 depois, 1 antes (contexto)
```

> **Regra:** Para scripts, **sempre use `grep -E`** (regex estendida). `grep -P` não é portável.

---

## 2. sed — transformar fluxo

```bash
sed 's/antigo/novo/' arquivo         # primeira ocorrência por linha
sed 's/antigo/novo/g' arquivo        # global (todas na linha)
sed 's/antigo/novo/gi' arquivo       # global + case-insensitive
sed '2,5d' arquivo                   # apaga linhas 2 a 5
sed '/^#/d' arquivo                  # apaga linhas que começam com #
sed -n '1,10p' arquivo               # imprime só linhas 1-10 (-n suprime auto-print)
sed 's/$/;/' arquivo                 # adiciona ; no fim de cada linha
sed 's/^[[:space:]]*//' arquivo      # remove espaços do início
```

| Comando | Efeito |
|---------|--------|
| `s/old/new/` | substitui |
| `g` | global (todas ocorrências na linha) |
| `d` | apaga linha |
| `p` | imprime linha (use com `-n`) |
| `y/a/b/` | translitera chars (a→b) |

> **Dica:** Use delimitador diferente se pattern tem `/`: `s|/home|/tmp|g`

---

## 3. awk — processamento de colunas

```bash
# Imprime coluna 1 e 3
awk '{print $1, $3}' arquivo

# Separador customizado
awk -F: '{print $1, $3}' /etc/passwd

# Filtra + processa
awk '$3 > 100 {print $1, $3}' arquivo

# Variáveis especiais
awk 'BEGIN {FS=":"} {print NR ": " $1} END {print "Total: " NR}' arquivo

# Cálculos
awk '{soma += $2} END {print "Soma:", soma; print "Média:", soma/NR}' arquivo

# Arrays associativos (contagem)
awk '{count[$1]++} END {for (k in count) print k, count[k]}' arquivo
```

| Variável | Significado |
|----------|-------------|
| `NR` | Número do registro (linha) atual |
| `NF` | Número de campos na linha atual |
| `$0` | Linha inteira |
| `$1..$N` | Campos |
| `FS` | Input field separator (default: espaço) |
| `OFS` | Output field separator (default: espaço) |
| `BEGIN` | Executa ANTES de ler arquivo |
| `END` | Executa DEPOIS de ler arquivo |

---

## 4. Escolhendo a ferramenta

| Tarefa | Ferramenta |
|--------|------------|
| "Acha linhas com X" | `grep` |
| "Substitui X por Y" | `sed` |
| "Coluna 3 > 100, soma coluna 2" | `awk` |
| "Remove linhas vazias" | `sed '/^$/d'` ou `grep -v '^$'` |
| "Conta ocorrências por IP" | `awk '{ip[$1]++} END{for(i in ip) print i, ip[i]}'` |

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `grep` acha parte da palavra | `grep "erro"` acha "erros" | `grep -w "erro"` (palavra inteira) |
| `sed` não substitui todas | Falta `g` | `sed 's/old/new/g'` |
| `awk` divide errado | Espaços múltiplos | `awk -F'[[:space:]]+'` ou default já trata |
| `awk` array não ordena | `for (k in count)` ordem aleatória | Pipe para `sort` ou use `asorti` (GNU awk) |

---

## Prática

### Exemplos conceituais
- [`exemplos/conceito-grep.sh`](exemplos/conceito-grep.sh) — grep variantes
- [`exemplos/conceito-sed.sh`](exemplos/conceito-sed.sh) — sed substituição, deleção
- [`exemplos/conceito-awk.sh`](exemplos/conceito-awk.sh) — awk colunas, cálculos, arrays
- [`exemplos/conceito-pipeline.sh`](exemplos/conceito-pipeline.sh) — combinação real

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 6 exercícios + autoavaliação.

---

## Autoavaliação

- [ ] Sei usar `grep -E`, `-v`, `-i`, `-c`, `-n`, `-A/-B/-C`, `-r`
- [ ] Sei `sed s///g`, `d`, `-n p`, endereços (linha, range, pattern)
- [ ] Sei `awk` colunas (`$1`), `FS/OFS`, `NR/NF`, `BEGIN/END`, arrays
- [ ] Sei combinar: `grep | sed | awk` em pipeline
- [ ] Sei escolher ferramenta certa para a tarefa

Se marcou todos, siga para o [Módulo 09](../09-arrays-e-expansoes/).