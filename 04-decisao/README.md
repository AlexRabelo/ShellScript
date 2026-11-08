# Módulo 04: Decisão — if, elif, else, case

> **Analogia:** `if` é uma **encruzilhada** — o script escolhe um caminho baseado na condição. `case` é um **painel de botões** — cada valor dispara uma ação diferente, mais limpo quando há muitas opções.

## Objetivos

Ao final deste módulo você será capaz de:

- Escrever `if`, `elif`, `else` com condições compostas
- Usar `case` para despachar por valor exato, glob pattern ou regex
- Entender que `[[ ]]` e `(( ))` são comandos que retornam código de saída
- Evitar armadilhas: `;` obrigatório antes de `then`, aspas em variáveis, `;;` em `case`

---

## 1. if / elif / else

```bash
if [[ -f "$arquivo" ]]; then
    echo "É arquivo"
elif [[ -d "$arquivo" ]]; then
    echo "É diretório"
else
    echo "Não existe ou é outro tipo"
fi
```

**Regras de sintaxe:**
- `then` na **mesma linha** do `if`/`elif` (ou separado por `;`)
- `fi` fecha o bloco
- Condição pode ser qualquer comando — usa seu código de saída (0 = verdadeiro)

```bash
# Exemplo: grep retorna 0 se achou, 1 se não achou
if grep -q "erro" log.txt; then
    echo "Tem erro no log"
fi
```

---

## 2. case — despacho por padrão

```bash
acao="$1"

case "$acao" in
    start)
        echo "Iniciando..."
        ;;
    stop)
        echo "Parando..."
        ;;
    restart|reload)
        echo "Reiniciando..."
        ;;
    status)
        echo "Verificando status..."
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status}"
        exit 2
        ;;
esac
```

| Padrão | Casa com |
|--------|----------|
| `start` | exatamente "start" |
| `restart|reload` | "restart" OU "reload" |
| `*.log` | glob: termina com .log |
| `?` | exatamente 1 caractere |
| `*` | **qualquer coisa** (default) — **sempre por último** |

> **Dica:** `case` usa **glob patterns**, não regex. Para regex, use `if [[ $var =~ regex ]]`.

---

## 3. Condicional em uma linha

```bash
[[ -f "$arq" ]] && echo "existe" || echo "não existe"

# Cuidado: A && B || C  NÃO é if-then-else!
# Se A=true e B=false, C executa mesmo assim.
# Forma segura:
if [[ -f "$arq" ]]; then echo "existe"; else echo "não existe"; fi
```

---

## 4. case com regex (Bash 4+)

```bash
# Bash 4+ suporta regex em case com shopt
shopt -s nocasematch  # case-insensitive
case "$entrada" in
    [Ss][Ii][Mm]) echo "sim";;
    [Nn][Aa][Oo]) echo "não";;
esac
```

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `syntax error near 'then'` | Falta `;` ou quebra de linha antes de `then` | `if [[ cond ]]; then` ou `if [[ cond ]]\nthen` |
| Variável vazia quebra teste | `[[ $var = x ]]` com var vazio | `[[ "$var" = x ]]` (aspas!) |
| `case` não casa padrão | Espaço no padrão ou `;;` faltando | `pattern)` sem espaços, `;;` obrigatório |
| `A && B || C` executa C errado | Não é if-then-else | Use `if/then/else` explícito |

---

## Prática

### Exemplos conceituais
- [`exemplos/conceito-if.sh`](exemplos/conceito-if.sh) — if/elif/else aninhado
- [`exemplos/conceito-case.sh`](exemplos/conceito-case.sh) — case com glob, default
- [`exemplos/conceito-case-regex.sh`](exemplos/conceito-case-regex.sh) — case com regex

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 5 exercícios + autoavaliação.

---

## Autoavaliação

- [ ] Sei escrever if/elif/else com `then` na linha correta
- [ ] Sei usar case com padrões exatos, glob (`*`), alternância (`|`)
- [ ] Sei por que `A && B || C` não substitui if/then/else
- [ ] Sei que `case` usa glob, não regex (exceto com `shopt`)
- [ ] Sei testar código de saída de comando direto no `if`

Se marcou todos, siga para o [Módulo 05](../05-lacos/).