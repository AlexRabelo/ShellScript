# Exercícios: Módulo 06 — Funções

Crie os scripts em `~/ex06/`. Consulte o [gabarito](gabarito/) só depois de tentar.

---

## Exercícios

### 1. Função com validação de argumento
**Arquivo:** `funcao-valida.sh`
- Função `saudacao(nome)` que:
  - Valida que `$1` não é vazio (`-z`)
  - Se vazio: imprime "Erro: nome obrigatório" >&2 e `return 2`
  - Se ok: imprime "Olá, $nome!" e `return 0`
- Teste: `saudacao ""`, `saudacao "Ana"`

### 2. Retorno via stdout — calculadora
**Arquivo:** `funcao-stdout.sh`
- Funções: `soma(a,b)`, `sub(a,b)`, `mul(a,b)`, `div(a,b)` — todas retornam resultado via `echo`
- `div` valida divisão por zero: imprime erro >&2 e `return 1`
- Script principal: lê 2 números e operador, chama função apropriada, imprime resultado

### 3. Scope com local
**Arquivo:** `funcao-scope.sh`
- Variável global: `total=0`
- Função `adiciona(valor)` que:
  - Cria `local total=0`
  - Soma valor ao local
  - Imprime "Local: $total"
- Chame `adiciona 10`, `adiciona 20`
- Imprima global `total` (deve ser 0)

### 4. Processa lista com shift
**Arquivo:** `funcao-shift.sh`
- Função `prefixa_linhas(prefixo, ...)` que:
  - Guarda `$1` em `local prefixo`
  - `shift`
  - Itera `"$@"` e imprime "$prefixo: $linha"
- Teste com 5 argumentos

### 5. Recursão — fatorial iterativo vs recursivo
**Arquivo:** `funcao-recursao.sh`
- Implemente `fatorial_rec(n)` recursivo
- Implemente `fatorial_iter(n)` iterativo (loop for)
- Teste ambos com 0 a 10
- Compare resultados

### 6. Função que usa variável global intencionalmente
**Arquivo:** `funcao-global.sh`
- Array global: `logs=()`
- Função `loga(msg)` que faz `logs+=("$(date '+%H:%M:%S') $msg")`
- Função `mostra_logs()` que itera e imprime
- Chame `loga "iniciando"`, `loga "processando"`, `loga "fim"`
- Chame `mostra_logs`

---

## Autoavaliação

- [ ] Sei definir função e usar `local` para variáveis internas
- [ ] Sei retornar status (0=sucesso, 1-255=erro) com `return`
- [ ] Sei retornar dados via `stdout` e capturar com `$(funcao)`
- [ ] Sei usar `shift` para processar argumentos variáveis
- [ ] Sei escrever recursão com caso base correto
- [ ] Sei quando usar variável global intencionalmente (ex: acumulador)

Se marcou todos, siga para o [Módulo 07](../../07-menus-e-entrada/).