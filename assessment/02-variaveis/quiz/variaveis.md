# Quiz: Módulo 02 — Variáveis e Parâmetros

**Tempo:** 10 min | **Pontuação:** 10 pts | **Passe:** 7/10

---

## 1. Atribuição correta (1 pt)
Qual das seguintes atribuições é **válida** em Bash?

- [ ] `nome = "servidor"`
- [ ] `nome="servidor"`
- [ ] `nome = "servidor" `
- [ ] `nome ="servidor"`

---

## 2. Expansão com default (1 pt)
Dado `versao=""`, o que imprime `echo "${versao:-1.24}"`?

- [ ] `1.24`
- [ ] (linha vazia)
- [ ] `versao`
- [ ] erro de sintaxe

**A variável `versao` muda de valor após isso?**
- [ ] Sim, passa a valer `1.24`
- [ ] Não, continua vazia

---

## 3. Expansão com atribuição (1 pt)
Dado `ip=""`, o que imprime `echo "${ip:=192.168.1.1}"` e qual o valor de `ip` depois?

- [ ] Imprime `192.168.1.1`, `ip` continua vazio
- [ ] Imprime `192.168.1.1`, `ip` passa a valer `192.168.1.1`
- [ ] Imprime vazio, `ip` continua vazio
- [ ] Erro de sintaxe

---

## 4. Arrays indexados (1 pt)
Como iterar **corretamente** sobre um array `servidores=("web01" "web02" "db01")`?

- [ ] `for s in ${servidores[@]}; do ...`
- [ ] `for s in "${servidores[@]}"; do ...`
- [ ] `for s in ${servidores[*]}; do ...`
- [ ] `for s in "${servidores[*]}"; do ...`

---

## 5. Arrays associativos (1 pt)
O que **falta** no código abaixo para funcionar?

```bash
cores["vermelho"]="#FF0000"
cores["verde"]="#00FF00"
```

- [ ] `declare -A cores` antes das atribuições
- [ ] `declare -a cores` antes das atribuições
- [ ] `export cores` antes das atribuições
- [ ] Nada, já está correto

---

## 6. Parâmetros posicionais (1 pt)
Qual a diferença entre `"$@"` e `$*` (sem aspas)?

- [ ] São iguais
- [ ] `"$@"` preserva argumentos com espaços; `$*` junta tudo numa string
- [ ] `$*` preserva argumentos; `"$@"` junta tudo
- [ ] `"$@"` só funciona em funções

---

## 7. Escopo em funções (1 pt)
```bash
x=10
funcao() { local x=5; x=7; echo "in: $x"; }
funcao
echo "out: $x"
```
O que imprime?

- [ ] `in: 7` / `out: 7`
- [ ] `in: 7` / `out: 10`
- [ ] `in: 5` / `out: 10`
- [ ] `in: 10` / `out: 10`

---

## 8. Expansão de substring (1 pt)
Dado `path="/home/user/docs/arquivo.txt"`, qual expansão retorna **apenas o diretório** (`/home/user/docs`)?

- [ ] `${path#*/}`
- [ ] `${path##*/}`
- [ ] `${path%/*}`
- [ ] `${path%%/*}`

---

## 9. Leitura de CSV em array (1 pt)
Qual comando lê uma linha CSV `nome,idade,cidade` em três variáveis?

- [ ] `IFS=, read -r nome idade cidade <<< "$linha"`
- [ ] `read -r nome,idade,cidade <<< "$linha"`
- [ ] `IFS="," read nome idade cidade <<< "$linha"`
- [ ] `read -a arr <<< "$linha"`

---

## 10. mapfile (1 pt)
Qual flag do `mapfile` remove o `\n` final de cada linha?

- [ ] `-n`
- [ ] `-r`
- [ ] `-t`
- [ ] `-d`

---

## Gabarito
1. B  | 2. A + Não  | 3. B  | 4. B  | 5. A  | 6. B  | 7. B  | 8. C  | 9. A  | 10. C

---

## Critério de Avaliação
- **9-10:** Domínio sólido — pode avançar
- **7-8:** Revisar tópicos errados — refazer exercícios
- **<7:** Releia o módulo — foque em expansões e arrays