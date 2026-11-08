# Gabarito e Explicações: Módulo 06

## 1. lib/eh_numero.sh
**Conceitos:** Função simples de validação, regex `^-?[0-9]+$`, nameref não necessário.

```bash
eh_numero() {
    local str="${1:-}"
    [[ "$str" =~ ^-?[0-9]+$ ]]
}
```
- `local str="${1:-}"` captura argumento com fallback vazio.
- `=~` com regex: `-?` = sinal opcional, `[0-9]+` = 1 ou mais dígitos.

---

## 2. lib/log.sh
**Conceitos:** Biblioteca de log profissional, cores ANSI condicionais, níveis, `die`.

```bash
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    COR_RESET="\033[0m"
    ...
fi
```
- `-t 1`: verifica se stdout é terminal (TTY). Em cron/pipe, desativa cores.
- `NO_COLOR`: variável padrão da indústria (https://no-color.org/) para forçar sem cores.
- `>&2` em aviso/erro: separa logs de dados (stdout) de diagnósticos (stderr).

---

## 3. backup-tool.sh
**Conceitos:** Script completo com `main "$@"`, `getopts` manual, modo estrito, bibliotecas.

```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o) ORIGEM="${2:-}"; shift 2 ;;
        -d) DESTINO="${2:-}"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        -h|--help) uso; exit 0 ;;
        *) die "Opção desconhecida: $1" 2 ;;
    esac
done
```
- `shift 2` consome a flag e seu valor.
- `main "$@"` passa todos os args do script para a main.
- `trap` captura INT (Ctrl+C), TERM e ERR (erros com `set -e`).

---

## 4. lib/retry.sh
**Conceitos:** Função genérica de retry, captura de saída e código, shift para separar parâmetros.

```bash
retry() {
    local max_tentativas="${1:-3}"
    local intervalo="${2:-2}"
    shift 2  # Remove max e intervalo, sobra apenas o comando + args
    ...
    saida=$("$@" 2>&1)  # Executa comando passado
}
```
- `shift 2` deixa em `$@` apenas o comando e seus argumentos.
- `"$@"` expande preservando aspas e espaços nos argumentos.
- Captura stderr junto (`2>&1`) para mostrar em caso de falha.

---

## 5. lib/inventario.sh
**Conceitos:** Arrays associativos, `nameref` (`local -n`), parsing CSV.

```bash
local -n arr="$2"  # Bash 4.3+: referência ao array passado pelo nome
arr["$host"]="${ip},${ambiente},${role}"
```
- `local -n` permite modificar o array do chamador (passa por referência).
- Chave = hostname, Valor = string "IP,AMBIENTE,ROLE".
- `filtra_por_ambiente` e `contagem_por_ambiente` iteram sobre chaves.

---

## 6. lib/disco.sh + checa-disco-refatorado.sh
**Conceitos:** Refatoração em biblioteca reutilizável, códigos de saída semânticos.

```bash
verifica_disco() {
    ...
    if (( uso >= critico )); then
        echo "CRÍTICO..." >&2
        return 2
    elif (( uso >= aviso )); then
        echo "AVISO..." >&2
        return 1
    else
        echo "OK..."
        return 0
    fi
}
```
- Códigos: 0=OK, 1=AVISO, 2=CRÍTICO, 3=ERRO (parâmetros inválidos ou ponto inexistente).
- Script refatorado apenas importa e delega.

---

## 7. idempotente-usuario.sh
**Conceitos:** Idempotência (rodar N vezes = mesmo resultado), `id`, `useradd`, `usermod`.

```bash
if id "$USUARIO" >/dev/null 2>&1; then
    # Existe: apenas atualiza se diferente
    shell_atual=$(getent passwd "$USUARIO" | cut -d: -f7)
    [[ "$shell_atual" != "$SHELL_USER" ]] && usermod -s "$SHELL_USER" "$USUARIO"
else
    # Não existe: cria
    useradd -m -s "$SHELL_USER" -G "$GRUPOS" "$USUARIO"
fi
```
- Sempre exit 0 (sucesso), logs informam ação realizada.
- `getent passwd` consulta NSS (funciona com LDAP/AD, não só /etc/passwd).

---

## 8. carrega-libs.sh
**Conceitos:** Busca de bibliotecas em múltiplos prefixos (local, system, opt).

```bash
carrega_biblioteca() {
    local caminhos=(
        "${SCRIPT_DIR}/lib/${nome}.sh"
        "/usr/local/lib/${nome}.sh"
        "/opt/lib/${nome}.sh"
    )
    for caminho in "${caminhos[@]}"; do
        [[ -f "$caminho" ]] && { source "$caminho"; return 0; }
    done
    die "Não encontrada"
}
```
- Permite instalar libs em `/usr/local/lib` para uso global.

---

## 9. lib/processos.sh
**Conceitos:** `pgrep`, `mapfile` (retorno de array), escalonamento de sinal TERM -> KILL.

```bash
mapfile -t pids < <(pgrep -u "$usuario" 2>/dev/null || true)
```
- `mapfile` (ou `readarray`) lê linhas em array.
- Process substitution `< <(comando)` evita subshell do pipe.
- `|| true` evita falha do `set -e` se pgrep não encontrar nada.

---

## 10. lib/exec.sh
**Conceitos:** Wrapper de execução, `DRY_RUN` global, array para comando.

```bash
executa() {
    local cmd=("$@")
    if (( DRY_RUN )); then
        log_aviso "[DRY-RUN] ${cmd[*]}"
        return 0
    fi
    log_info "EXEC: ${cmd[*]}"
    "${cmd[@]}"
    ...
}
```
- `local cmd=("$@")` preserva argumentos como array (espaços, aspas).
- `"${cmd[@]}"` expande corretamente cada elemento.
- `DRY_RUN=1` permite simulação completa sem executar nada.

---

## Boas Práticas SRE para Funções e Bibliotecas

| Prática | Por que |
|---|---|
| `local` em **todas** variáveis internas | Evita vazamento silencioso (bug difícil de achar) |
| Funções pequenas, um propósito | Testáveis, reutilizáveis, legíveis |
| `return 0-255` só para status | `return` não aceita strings |
| `echo "valor"` para dados | Captura com `var=$(funcao)` |
| `source` com `BASH_SOURCE[0]` | Funciona de qualquer diretório |
| `main "$@"` no final | Permite `source script.sh` sem executar |
| Bibliotecas sem `set -e` | Não impõem modo ao consumidor |
| Prefixo `lib/` nas funções | Evita colisão de nomes (`lib_log_info`) |