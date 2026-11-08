# Módulo 03: Testes e Operadores

> **Analogia:** testes são **perguntas de sim/não** que o script faz ao sistema. `[ ]` é a pergunta formal; `[[ ]]` é a versão turbinada que entende melhor o português (regex, strings vazias, operadores lógicos).

## Objetivos

Ao final deste módulo você será capaz de:

- Usar `[ ]` (POSIX) e `[[ ]]` (Bash) para comparar strings, números e arquivos
- Escolher o operador certo: `=`, `==`, `!=`, `-z`, `-n`, `-eq`, `-lt`, `-gt`, `-f`, `-d`, `-r`, `-w`, `-x`
- Combinar testes com `&&`, `||`, `!`, `-a`, `-o` (dentro de `[ ]`) ou `&&`, `||`, `!` (dentro de `[[ ]]`)
- Entender precedência e agrupar com parênteses
- Depurar testes com `bash -x` e `set -v`

---

## 1. Dois comandos de teste

| Comando | Tipo | Use quando |
|---------|------|------------|
| `[ expr ]` | POSIX (builtin `test`) | Scripts que rodam em `sh` (não só `bash`) |
| `[[ expr ]]` | Bash builtin | **Sempre preferir em Bash** — mais seguro, mais operadores |

> **Regra:** Em scripts com `#!/usr/bin/env bash`, use **sempre `[[ ]]`**. Só use `[ ]` se precisar de portabilidade POSIX estrita.

---

## 2. Comparação de strings

```bash
nome="servidor"

[[ -z "$nome" ]]        # string VAZIA? (zero length)
[[ -n "$nome" ]]        # string NÃO vazIA?
[[ "$nome" = "servidor" ]]    # igual (POSIX: = ; Bash: = ou ==)
[[ "$nome" != "outro" ]]      # diferente
[[ "$nome" == s* ]]           # glob pattern (só em [[ ]])
[[ "$nome" =~ ^s.*r$ ]]       # REGEX (só em [[ ]]) — use aspas na regex se tiver espaços
```

> **Armadilha:** em `[ ]`, `>` e `<` fazem redirecionamento! Em `[[ ]]`, fazem comparação lexicográfica.

---

## 3. Comparação numérica

```bash
idade=25
limite=18

(( idade > limite ))        # ARITMÉTICA — preferida para números
[[ $idade -gt $limite ]]    # TESTE numérico (dentro de [[ ]])
[ $idade -gt $limite ]      # TESTE numérico (dentro de [ ])
```

| Operador | Significado | Onde funciona |
|----------|-------------|---------------|
| `-eq` | igual | `[ ]`, `[[ ]]` |
| `-ne` | diferente | `[ ]`, `[[ ]]` |
| `-lt` | menor que | `[ ]`, `[[ ]]` |
| `-le` | menor ou igual | `[ ]`, `[[ ]]` |
| `-gt` | maior que | `[ ]`, `[[ ]]` |
| `-ge` | maior ou igual | `[ ]`, `[[ ]]` |
| `(( a > b ))` | maior que (C-style) | **só `(( ))`** — **use esta** |

> **Regra prática:** Para números, **use `(( ))`**. É mais legível, permite `>=`, `<=`, `++`, `--`, e não precisa de `$` nas variáveis.

---

## 4. Testes de arquivo

```bash
arquivo="/etc/passwd"
dir="/etc"

[[ -e "$arquivo" ]]    # existe (arquivo, dir, link, etc)
[[ -f "$arquivo" ]]    # é arquivo regular
[[ -d "$dir" ]]        # é diretório
[[ -L "$arquivo" ]]    # é link simbólico
[[ -r "$arquivo" ]]    # legível (pelo usuário atual)
[[ -w "$arquivo" ]]    # gravável
[[ -x "$arquivo" ]]    # executável
[[ -s "$arquivo" ]]    # tamanho > 0 (não vazio)
[[ "$arquivo" -nt "$outro" ]]  # mais novo que (modification time)
[[ "$arquivo" -ot "$outro" ]]  # mais velho que
```

---

## 5. Operadores lógicos e precedência

```bash
# Dentro de [[ ]] — use && || !
[[ -f "$arquivo" && -r "$arquivo" ]]    # E
[[ -f "$arquivo" || -d "$arquivo" ]]    # OU
[[ ! -f "$arquivo" ]]                   # NÃO

# Agrupamento com parênteses (precisa escapar ou usar (( )))
[[ ( -f "$a" || -f "$b" ) && -r "$a" ]]

# Dentro de [ ] — use -a -o ! (mas evite; use dois [ ] com && || fora)
[ -f "$arquivo" -a -r "$arquivo" ]      # antigo, propenso a erro
```

> **Regra:** Use `[[ ]]` com `&&`, `||`, `!` e parênteses `()`. Esqueça `-a`, `-o`.

---

## 6. Aritmética com `(( ))`

```bash
(( x = 10 + 5 ))        # atribuição
(( x++ ))               # incremento
(( x += 3 ))            # adição
(( resultado = x * 2 )) # expressão complexa

# Uso em condicional
if (( x > 10 )); then
    echo "maior que 10"
fi
```

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `[[ $var = pattern ]]` falha | Aspas no pattern desativam glob | `[[ $var = pattern ]]` (sem aspas no pattern) |
| Regex `=~` case-sensitive | `=~` é case-sensitive por padrão | `shopt -s nocasematch` ou use `${var,,}` |
| Variável vazia em `-eq` | `[ -z "$x" ] || [ "$x" -eq 5 ]` | `[[ -z $x || $x -eq 5 ]]` ou `(( x == 5 ))` com `x=0` default |
| Precedência errada | `[[ A && B || C ]]` = `(A && B) || C` | Use parênteses: `[[ A && (B || C) ]]` |
| `[ $var > 10 ]` | Redireciona saída para arquivo "10" | `[[ $var > 10 ]]` ou `(( var > 10 ))` |

---

## Prática

### Exemplos conceituais
- [`exemplos/conceito-strings.sh`](exemplos/conceito-strings.sh) — `-z`, `-n`, `=`, `!=`, `=~`
- [`exemplos/conceito-numericos.sh`](exemplos/conceito-numericos.sh) — `(( ))`, `-eq`, `-gt`
- [`exemplos/conceito-arquivos.sh`](exemplos/conceito-arquivos.sh) — `-f`, `-d`, `-r`, `-nt`
- [`exemplos/conceito-logicos.sh`](exemplos/conceito-logicos.sh) — `&&`, `||`, `!`, `()`

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 6 exercícios + autoavaliação.

---

## Autoavaliação

- [ ] Sei diferença entre `[ ]` e `[[ ]]` e quando usar cada
- [ ] Sei testar string vazia (`-z`), não vazia (`-n`), igualdade, regex
- [ ] Sei comparar números com `(( ))` (preferido) e `-eq`/`-gt`
- [ ] Sei testar existência, tipo, permissão de arquivo
- [ ] Sei combinar testes com `&&`, `||`, `!` e parênteses em `[[ ]]`
- [ ] Sei por que `[ $var > 10 ]` está errado

Se marcou todos, siga para o [Módulo 04](../04-decisao/).