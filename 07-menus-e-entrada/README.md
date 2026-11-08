# Módulo 07: Menus e Entrada — select, read, getopts

> **Analogia:** `select` é um **menu numerado** de restaurante — o cliente vê as opções, digita o número, o garçom (script) executa. `read` é **perguntar ao cliente** o que ele quer. `getopts` é **ler o pedido escrito** no papel (flags de linha de comando).

## Objetivos

Ao final deste módulo você será capaz de:

- Criar menus interativos com `select` (loop até `break`)
- Ler entrada do usuário com `read` (opções: `-p`, `-r`, `-s`, `-t`, `-n`)
- Parsear flags de linha de comando com `getopts` (curta `-f` e longa `--file`)
- Validar e sanitizar entrada do usuário
- Criar CLI profissional com ajuda (`-h`), verbose (`-v`), dry-run (`-n`)

---

## 1. select — menu numerado automático

```bash
opcoes=("Opção 1" "Opção 2" "Sair")

select escolha in "${opcoes[@]}"; do
    case "$escolha" in
        "Opção 1") echo "Você escolheu 1";;
        "Opção 2") echo "Você escolheu 2";;
        "Sair") echo "Tchau!"; break;;
        *) echo "Inválido: $REPLY";;
    esac
done
```

- `PS3` define o prompt (padrão: `#? `)
- `REPLY` guarda o que o usuário digitou
- Loop **infinito** até `break` ou `exit`

---

## 2. read — ler entrada do usuário

```bash
read -p "Nome: " nome                    # prompt inline
read -r linha                            # -r: raw (não interpreta \)
read -s -p "Senha: " senha; echo         # -s: silencioso (não ecoa)
read -t 5 -p "Rápido (5s): " resp || echo "Tempo esgotado"
read -n 1 -p "Continuar? [s/N] " yn      # -n 1: lê 1 char
```

| Flag | Efeito |
|------|--------|
| `-p "msg"` | Prompt sem newline |
| `-r` | Raw — não interpreta backslash |
| `-s` | Silent — não ecoa (senhas) |
| `-t N` | Timeout N segundos |
| `-n N` | Lê N caracteres (não espera Enter) |
| `-a arr` | Lê em array (palavras separadas por IFS) |

---

## 3. getopts — flags curtas POSIX

```bash
# getopts "ab:c:" opt
# a = flag sem argumento
# b: = flag COM argumento obrigatório (dois pontos)
# c: = flag COM argumento obrigatório

while getopts "hvn:f:" opt; do
    case "$opt" in
        h) usage; exit 0 ;;
        v) VERBOSE=1 ;;
        n) DRY_RUN=1 ;;
        f) ARQUIVO="$OPTARG" ;;
        *) usage >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))  # remove flags processadas, sobram args posicionais
```

- `OPTARG` guarda o argumento da flag (ex: `-f arquivo.txt` → `OPTARG="arquivo.txt"`)
- `OPTIND` é o índice do próximo argumento

---

## 4. Flags longas (--file) — workaround Bash

```bash
# getopts não suporta --longo nativamente
# Workaround: converta --longo para -x antes do getopts

args=()
for arg in "$@"; do
    case "$arg" in
        --help) args+=("-h") ;;
        --verbose) args+=("-v") ;;
        --dry-run) args+=("-n") ;;
        --file=*) args+=("-f" "${arg#*=}") ;;
        *) args+=("$arg") ;;
    esac
done
set -- "${args[@]}"  # reposiciona $@
# agora use getopts normal
```

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `read` pula entrada | Buffer sujo (ex: depois de `select`) | `read -r` ou limpe buffer |
| `getopts` não vê `--longo` | Só suporta flags curtas | Converter antes (ver acima) |
| Variável vazia em `case` | `REPLY` vazio ou padrão não casa | `*)` default sempre no final |
| Loop `select` não sai | Esqueceu `break` | `break` obrigatório na opção de saída |

---

## Prática

### Exemplos conceituais
- [`exemplos/conceito-select.sh`](exemplos/conceito-select.sh) — menu básico
- [`exemplos/conceito-read.sh`](exemplos/conceito-read.sh) — read com flags
- [`exemplos/conceito-getopts.sh`](exemplos/conceito-getopts.sh) — flags curtas + longas

### Exemplos nível produção (com template completo)
- [`exemplos/integracao/producao-parse-args.sh`](exemplos/integracao/producao-parse-args.sh) — parsing robusto com validação (conceitos de M02 aplicados aqui)

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 5 exercícios + autoavaliação.

---

## Autoavaliação

- [ ] Sei criar menu com `select` e sair com `break`
- [ ] Sei usar `read -p`, `-r`, `-s`, `-t`, `-n`
- [ ] Sei parsear flags curtas com `getopts` e `OPTARG`
- [ ] Sei converter flags longas (`--file`) para `getopts`
- [ ] Sei validar entrada (não vazio, numérico, opções válidas)

Se marcou todos, siga para o [Módulo 08](../08-processamento-de-texto/).