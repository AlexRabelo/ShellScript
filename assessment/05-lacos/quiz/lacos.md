# Quiz: Módulo 05 — Laços (for, while, until)

**Tempo:** 10 min | **Pontuação:** 10 pts | **Passe:** 7/10

---

## 1. Iteração sobre array (1 pt)
Qual a forma **correta** de iterar sobre `arr=("a" "b c" "d")` preservando o espaço em `"b c"`?

- [ ] `for x in ${arr[@]}; do ...`
- [ ] `for x in "${arr[@]}"; do ...`
- [ ] `for x in ${arr[*]}; do ...`
- [ ] `for x in "${arr[*]}"; do ...`

---

## 2. while read linha a linha (1 pt)
Por que `cat arquivo | while read linha; do ...` pode falhar ao modificar variáveis?

- [ ] Pipe cria subshell; variáveis não voltam ao shell pai
- [ ] `read` não funciona com pipe
- [ ] `cat` bufferiza a saída
- [ ] `while` não aceita pipe

---

## 3. until vs while (1 pt)
`until [[ -f /tmp/pronto ]]; do sleep 1; done` faz o quê?

- [ ] Roda **enquanto** o arquivo **não existe**
- [ ] Roda **enquanto** o arquivo **existe**
- [ ] Roda **uma vez** e para
- [ ] Entra em loop infinito

---

## 4. break vs continue (1 pt)
```bash
for i in {1..5}; do
    (( i == 3 )) && continue
    (( i == 4 )) && break
    echo $i
done
```
O que imprime?

- [ ] `1 2 3 4 5`
- [ ] `1 2 4 5`
- [ ] `1 2`
- [ ] `1 2 4`

---

## 4. Retry com backoff (1 pt)
No padrão de retry, qual a ordem correta das operações?

- [ ] Tenta → Se falha, incrementa contador → Dorme → Loop
- [ ] Incrementa contador → Tenta → Se falha, dorme → Loop
- [ ] Dorme → Tenta → Se falha, incrementa → Loop
- [ ] Tenta → Dorme → Incrementa → Loop

---

## 5. Sequência numérica (1 pt)
Qual **não** gera 1 a 5?

- [ ] `for i in {1..5}; do ...`
- [ ] `for (( i=1; i<=5; i++ )); do ...`
- [ ] `for i in $(seq 1 5); do ...`
- [ ] `for i in 1 2 3 4 5; do ...`

---

## 6. Glob em for (1 pt)
```bash
for f in *.log; do
    [[ -f "$f" ]] || continue
    echo "$f"
done
```
Por que o `[[ -f "$f" ]] || continue` é necessário?

- [ ] Para pular diretórios
- [ ] Se nenhum `.log` existe, glob expande para literal `"*.log"`
- [ ] Para evitar arquivos ocultos
- [ ] Para performance

---

## 7. Ler saída de comando em array (1 pt)
Qual a forma **segura** de ler `cmd` linha a linha em array?

- [ ] `arr=( $(cmd) )`
- [ ] `mapfile -t arr < <(cmd)`
- [ ] `for x in $(cmd); do arr+=("$x"); done`
- [ ] `readarray arr <<< "$(cmd)"`

---

## 8. break N (1 pt)
```bash
for i in {1..3}; do
    for j in {1..3}; do
        (( i == 2 && j == 2 )) && break 2
        echo "i=$i j=$j"
    done
done
```
Quantas linhas imprime?

- [ ] 9
- [ ] 4
- [ ] 3
- [ ] 0

---

## 9. IFS em while read (1 pt)
```bash
linha="a:b:c"
IFS=: read -r c1 c2 c3 <<< "$linha"
```
Qual o valor de `$c2`?

- [ ] `a`
- [ ] `b`
- [ ] `c`
- [ ] `a:b:c`

---

## 10. Armadilha for $(cmd) (1 pt)
Por que `for f in $(ls *.txt); do ...` é perigoso?

- [ ] `ls` não lista ocultos
- [ ] Word splitting + globbing quebram nomes com espaços
- [ ] `ls` é lento
- [ ] Não há perigo

---

## Gabarito
1. B | 2. A | 3. A | 4. C | 5. D | 6. B | 7. B | 8. B | 9. B | 10. B

---

## Critério de Avaliação
- **9-10:** Domínio sólido
- **7-8:** Revisar subshell, break N, mapfile
- **<7:** Releia módulo; foque em `while IFS= read -r`, `break 2`, `mapfile -t`