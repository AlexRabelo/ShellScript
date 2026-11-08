# Exercícios: Módulo 07 — Menus e Entrada

Crie os scripts em `~/ex07/`. Consulte o [gabarito](gabarito/) só depois de tentar.

---

## Exercícios

### 1. Menu de operações com select
**Arquivo:** `menu-operacoes.sh`
- Array com: "Somar", "Subtrair", "Multiplicar", "Dividir", "Sair"
- `select` loop: leia dois números com `read -p` antes de cada operação
- Use `case` no `$REPLY` (número) ou na string da opção
- Divisão por zero: trate com erro
- `break` só em "Sair"

### 2. Cadastro interativo com read
**Arquivo:** `cadastro.sh`
- `read -p` para: nome, email
- `read -s -p` para: senha (confirme com segundo `read -s`)
- Se senhas não conferem: erro e `exit 1`
- `read -t 10 -p "Confirma cadastro? [s/N] "` com timeout
- Valide email com regex `^[^@]+@[^@]+\.[^@]+$`
- No final, mostre resumo (sem senha)

### 3. CLI com getopts + flags longas
**Arquivo:** `cli-basico.sh`
- Flags: `-v/--verbose`, `-n/--dry-run`, `-f/--file ARQ`, `-o/--output ARQ`, `-h/--help`
- Valide que `-f` e `-o` recebem argumento
- Args posicionais restantes: imprima "Processando: $arg" para cada
- Modo dry-run: prefixe ações com `[DRY-RUN]`

### 4. Validador de entrada robusto
**Arquivo:** `valida-entrada.sh`
- Função `le_inteiro(prompt, min, max)` que:
  - Loop `while true`
  - `read -p "$prompt: " val`
  - Valida `[[ $val =~ ^-?[0-9]+$ ]]` e faixa min/max
  - Se inválido: imprime erro e repete
  - Se válido: `echo $val` e `return 0`
- Teste chamando 3 vezes com faixas diferentes

### 5. Menu com submenu (select aninhado)
**Arquivo:** `menu-aninhado.sh`
- Menu principal: "Usuários", "Serviços", "Rede", "Sair"
- Submenu "Usuários": "Listar", "Adicionar", "Remover", "Voltar"
- Submenu "Serviços": "Status", "Iniciar", "Parar", "Voltar"
- "Voltar" dá `break` no submenu e retorna ao principal
- Use funções para cada submenu

---

## Autoavaliação

- [ ] Sei criar menu com `select`, `PS3`, `REPLY`, `break`
- [ ] Sei usar `read -p`, `-r`, `-s`, `-t`, `-n`, `-a`
- [ ] Sei parsear flags com `getopts` e `OPTARG`
- [ ] Sei converter `--longas` para `getopts`
- [ ] Sei validar entrada em loop até ser válida

Se marcou todos, siga para o [Módulo 08](../../08-processamento-de-texto/).