# Quiz: Módulo 08 — Processamento de Texto (grep, sed, awk)

**Tempo:** 10 min | **Pontuação:** 10 pts | **Passe:** 7/10

---

## 1. grep -E vs -P (1 pt)
Por que **sempre usar `grep -E`** em scripts em vez de `-P`?

- [ ] `-E` é mais rápido
- [ ] `-P` (PCRE) não é portável; nem todo sistema tem suporte
- [ ] `-E` suporta mais metacaracteres
- [ ] `-P` é deprecated

---

## 2. sed substituição global (1 pt)
Dado `echo "a:b:c" | sed 's/:/;/'`, qual a saída?

- [ ] `a;b:c`
- [ ] `a;b;c`
- [ ] `a:b;c`
- [ ] erro

Como fazer **todas** as ocorrências?

- [ ] `s/:/;/g`
- [ ] `s/:/;/G`
- [ ] `s/:/;/all`
- [ ] `s/:/;/*`

---

## 3. awk separador customizado (1 pt)
Como imprimir colunas 1 e 3 de `/etc/passwd` (separador `:`)?

- [ ] `awk '{print $1, $3}' /etc/passwd`
- [ ] `awk -F: '{print $1, $3}' /etc/passwd`
- [ ] `awk -F: '{print $1 $3}' /etc/passwd`
- [ ] `awk ': {print $1, $3}' /etc/passwd`

---

## 4. awk variáveis especiais (1 pt)
O que `NR` e `NF` representam?

- [ ] `NR`=número do registro (linha), `NF`=número de campos na linha atual
- [ ] `NR`=número de campos, `NF`=número da linha
- [ ] `NR`=novo registro, `NF`=novo campo
- [ ] `NR`=número de registros total, `NF`=número de arquivos

---

## 5. Escolhendo a ferramenta (1 pt)
Qual ferramenta para: **"Conta ocorrências de cada IP único no access.log"**?

- [ ] `grep`
- [ ] `sed`
- [ ] `awk`
- [ ] `sort | uniq -c`

---

## 6. Pipeline grep|sed|awk (1 pt)
Ordem correta para: "Acha linhas com ERRO, extrai timestamp e mensagem, conta por hora"?

- [ ] `grep | awk | sed`
- [ ] `sed | grep | awk`
- [ ] `grep | sed | awk`
- [ ] `awk | grep | sed`

---

## 7. awk arrays associativos (1 pt)
`awk '{ip[$1]++} END {for(i in ip) print i, ip[i]}'` faz o quê?

- [ ] Conta quantas vezes cada IP ($1) aparece
- [ ] Soma valores do IP
- [ ] Lista IPs únicos
- [ ] Ordena IPs

---

## 8. grep contexto (1 pt)
`grep -A 2 -B 1 "erro" log.txt` mostra:

- [ ] 2 linhas depois, 1 antes de cada match
- [ ] 1 linha depois, 2 antes
- [ ] 2 linhas antes e depois
- [ ] Apenas linhas com "erro"

---

## 9. Armadilha grep palavra inteira (1 pt)
`grep "erro"` acha "erros", "erro", "terror". Como buscar **só** a palavra "erro"?

- [ ] `grep -w "erro"`
- [ ] `grep "^erro$"`
- [ ] `grep "\berro\b"`
- [ ] `grep " erro "`

---

## 10. awk ordenação (1 pt)
`for (i in ip)` itera em ordem:

- [ ] Alfabética das chaves
- [ ] Numérica dos valores
- [ ] Aleatória (hash table)
- [ ] Ordem de inserção

Como ordenar por contagem decrescente?

- [ ] Pipe para `sort -k2 -nr`
- [ ] `asorti(ip)` no END
- [ ] `PROCINFO["sorted_in"]="@val_num_desc"` (GNU awk)
- [ ] Todas acima funcionam

---

## Gabarito
1. B | 2. A + `s/:/;/g` | 3. B | 4. A | 5. C | 6. C | 7. A | 8. A | 9. A | 10. D

---

## Critério de Avaliação
- **9-10:** Domínio sólido
- **7-8:** Revisar pipeline order, awk arrays
- **<7:** Releia módulo; foque em escolha de ferramenta e awk END block