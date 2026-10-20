# Módulo 06: Funções

> **Analogia:** função é uma **máquina** que você constrói uma vez e usa quantas vezes quiser. Entra matéria-prima (argumentos), sai produto (stdout) e status (código de saída).

## Objetivos

Ao final deste módulo você será capaz de:

- Definir funções com `nome() { ... }` ou `function nome { ... }`
- Usar `local` para variáveis internas (evita vazamento)
- Retornar status com `return N` (0 = sucesso, 1-255 = falha)
- Retornar valores via `stdout` (command substitution: `$(funcao)`)
- Passar argumentos para funções (`$1`, `$2`, `"$@"`)
- Entender escopo: variáveis globais vs locais

---

## 1. Definindo funções

```bash
# Forma 1 (preferida, POSIX)
saudacao() {
    echo "Olá, $1!"
}

# Forma 2 (Bash, permite 'function' keyword)
function saudacao {
    echo "Olá, $1!"
}
```

---

## 2. Argumentos e retorno de status

```bash
eh_par() {
    local num="$1"
    (( num % 2 == 0 ))
    # return implícito = resultado da última expressão
}

eh_par 4 && echo "4 é par"      # return 0 (sucesso)
eh_par 5 || echo "5 é ímpar"    # return 1 (falha)
```

> **Regra:** `return` só aceita 0-255. Para retornar strings/números grandes, use `stdout` (echo).

---

## 3. Retornando valores via stdout

```bash
dobro() {
    local num="$1"
    echo $(( num * 2 ))
    # saída capturada com $(dobro 5)
}

resultado=$(dobro 7)
echo "Dobro de 7 = $resultado"   # 14
```

---

## 4. Escopo — `local` é obrigatório

```bash
contador=100

incrementa() {
    local contador=0        # LOCAL — não toca no global
    ((contador++))
    echo "Dentro: $contador"
}

incrementa
echo "Fora: $contador"      # ainda 100
```

> **Erro comum:** esquecer `local` → a função modifica a variável global acidentalmente.

---

## 5. `shift` dentro de função

```bash
processa_todos() {
    local prefixo="$1"
    shift                   # remove $1, $2 vira $1, etc
    for item in "$@"; do
        echo "$prefixo: $item"
    done
}

processa_todos "LOG" arquivo1.txt arquivo2.txt arquivo3.txt
```

---

## 6. Funções recursivas

```bash
fatorial() {
    local n="$1"
    if (( n <= 1 )); then
        echo 1
    else
        local prev=$(fatorial $((n - 1)))
        echo $(( n * prev ))
    done
}

echo "5! = $(fatorial 5)"   # 120
```

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| Variável vaza da função | Esqueceu `local` | **Sempre** `local var=valor` |
| `return "string"` falha | `return` só aceita 0-255 | Use `echo "string"` e capture com `$(funcao)` |
| Argumentos não funcionam | Usou `$1` fora da função | `$1` da função é independente do `$1` do script |
| Recursão estoura pilha | Sem caso base | Sempre teste condição de parada primeiro |

---

## Prática

### Exemplos conceituais
- [`exemplos/conceito-funcoes.sh`](exemplos/conceito-funcoes.sh) — definição, args, return, local
- [`exemplos/conceito-stdout.sh`](exemplos/conceito-stdout.sh) — retorno via stdout
- [`exemplos/conceito-recursao.sh`](exemplos/conceito-recursao.sh) — fatorial, fibonacci

### Exemplos nível produção (com template completo)
- [`exemplos/integracao/lib/`](exemplos/integracao/lib/) — bibliotecas reutilizáveis (log, valida)
- [`exemplos/integracao/script-com-main.sh`](exemplos/integracao/script-com-main.sh) — script completo com main, parsing, funções

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 6 exercícios + autoavaliação.

---

## Autoavaliação

- [ ] Sei definir função com `nome() { ... }`
- [ ] Sei usar `local` para isolar variáveis
- [ ] Sei retornar status (0/1) com `return` ou último comando
- [ ] Sei retornar dados via `stdout` e capturar com `$(funcao)`
- [ ] Sei passar `"$@"` para iterar argumentos da função
- [ ] Sei escrever recursão com caso base

Se marcou todos, siga para o [Módulo 07](../07-menus-e-entrada/).