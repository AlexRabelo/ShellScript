# Gabarito e Explicações: Módulo 07

## 1. menu-select-sub.sh
**Conceitos:** `select` nativo, submenus, `break 2` para sair de loops aninhados.

```bash
select opcao in ...; do
    case "$REPLY" in
        5) break 2 ;;  # Sai de DOIS níveis de loop (submenu + principal)
    esac
done
```
- `break N` sai de N níveis de laços `for`/`while`/`select`.
- `PS3` personaliza o prompt do `select`.

---

## 2. ferramenta-cli.sh
**Conceitos:** `getopts` para flags curtas, parse manual para `--longas`, validações, root check.

```bash
while getopts ':u:g:s:vfh' opt; do
    case "$opt" in
        u) USUARIO="$OPTARG" ;;
        :) die "Opção -$OPTARG requer argumento" 2 ;;
    esac
done
shift $((OPTIND - 1))
```
- `:` no início de `:u:g:s:vfh` suprime erro padrão do `getopts`.
- `u:` = flag `-u` requer argumento (guarda em `$OPTARG`).
- `v` sem `:` = flag booleana.
- `shift $((OPTIND - 1))` remove flags processadas.

---

## 3. confirma-acao.sh
**Conceitos:** Prompt seguro `[s/N]`, detecção de não-interativo, case-insensitive.

```bash
if [[ ! -t 0 ]]; then
    exit 1  # Seguro para cron: assume NÃO
fi
read -rp "${MENSAGEM} [s/N] " resposta
resposta="${resposta,,}"  # minúscula
```
- `[[ -t 0 ]]` evita `read` travado em cron/ssh não-interativo.
- `${var,,}` converte para minúscula (Bash 4.0+).

---

## 4. valida-entrada.sh
**Conceitos:** 4 funções reutilizáveis de validação com loop `while true`.

```bash
le_inteiro() {
    while true; do
        read -rp "$1 " valor
        [[ "$valor" =~ ^-?[0-9]+$ ]] || { echo "Inválido"; continue; }
        (( valor >= min && valor <= max )) || { echo "Fora da faixa"; continue; }
        echo "$valor"; return 0
    done
}
```
- Loop infinito até entrada válida.
- Retorna valor via `echo` (stdout), capturado com `var=$(le_inteiro ...)`.

---

## 5. parse-longas.sh
**Conceitos:** Parse manual de `--flag=valor` com `case` e remoção de prefixo `${arg#*=}`.

```bash
for arg in "$@"; do
    case "$arg" in
        --host=*) HOST="${arg#*=}" ;;
        --porta=*) PORTA="${arg#*=}" ;;
    esac
done
```
- `${arg#*=}` remove tudo até o primeiro `=` (prefixo curto).
- Suporta `--flag=valor` mas não `--flag valor` (espaço).

---

## 6. detecta-ambiente.sh
**Conceitos:** Detecção de TTY, root, container, CI, display, cores.

```bash
# Container
[[ -f /.dockerenv ]] || grep -q 'docker\|containerd' /proc/1/cgroup

# CI
for var in CI GITHUB_ACTIONS GITLAB_CI ...; do
    [[ -n "${!var:-}" ]] && echo "CI: $var"
done
```
- `/.dockerenv` existe em containers Docker.
- `/proc/1/cgroup` mostra cgroups do PID 1.
- `${!var}` = expansão indireta (valor da variável cujo nome está em `$var`).

---

## 7. spinner.sh
**Conceitos:** Spinner animado em background, `tput` para cursor, `wait` para sincronização.

```bash
inicia_spinner() {
    ( while true; do printf "\r${spin:i++%${#spin}:1} $msg"; sleep 0.1; done ) &
    spinner_pid=$!
}

para_spinner() {
    kill "$spinner_pid"; wait "$spinner_pid"
    tput cnorm  # restaura cursor
    printf "\r\033[K✓ $msg\n"  # \r = volta linha, \033[K = limpa linha
}
```
- Subshell `(...)` em background roda spinner enquanto comando principal executa.
- `tput civis`/`cnorm` esconde/mostra cursor.
- `\r\033[K` limpa a linha do spinner antes de imprimir resultado.

---

## 8. setup-inicial.sh
**Conceitos:** Menu completo de pós-instalação, dry-run padrão, funções modulares.

```bash
DRY_RUN=1  # Padrão seguro
executa() {
    if (( DRY_RUN )); then log_aviso "[DRY-RUN] $*"; else log_info "EXEC: $*"; "$@"; fi
}
```
- `DRY_RUN=1` por padrão impede acidentes.
- Funções `op_*` isolam cada ação.
- `case` no loop principal despacha para funções.

---

## 9. auto-help.sh
**Conceitos:** Arrays associativos para registro de comandos, dispatcher dinâmico.

```bash
declare -A CMD_DESC CMD_FUNC CMD_USAGE

registra_comando() {
    CMD_DESC["$1"]="$2"
    CMD_FUNC["$1"]="$3"
    CMD_USAGE["$1"]="$4"
}

main() {
    "${CMD_FUNC[$cmd]}" "$@"
}
```
- Padrão usado por `git`, `docker`, `kubectl` (subcomandos).
- `declare -A` permite mapa nome → função/descrição/uso.
- Adicionar comandos = apenas chamar `registra_comando`.

---

## Boas Práticas SRE para Menus e CLIs

| Prática | Por que |
|---|---|
| `DRY_RUN=1` por padrão | Evita operações destrutivas acidentais |
| `[[ -t 0 ]]` antes de `read` | Evita travamento em cron/CI |
| Cores só se `[[ -t 1 ]]` | Logs limpos em arquivos/pipes |
| Respeita `NO_COLOR` | Padrão da indústria para acessibilidade |
| `getopts` para flags curtas | Builtin, portável, robusto |
| Parse manual para `--longas` | `getopts` não suporta |
| Help auto-gerado | Evita documentação desatualizada |
| Confirmação `[s/N]` para ações perigosas | Prevenção de erro humano |