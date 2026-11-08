# Gabarito e Explicações: Módulo 04

## 1. classifica-carga.sh
**Conceitos:** leitura de `/proc/loadavg`, `nproc`, cálculo com `awk`, decisões com `if/elif/else`.

```bash
read -r carga _ < /proc/loadavg
cores=$(nproc)
carga_por_core=$(awk -v c="$carga" -v n="$cores" 'BEGIN { printf "%.2f", c/n }')
```
- `/proc/loadavg` tem: carga 1min, 5min, 15min, processos rodando/total, PID mais recente.
- `read -r carga _` ignora o resto da linha.
- `awk` faz a divisão decimal (Bash não faz float).
- Comparação com `awk` porque `(( ))` não suporta floats.

---

## 2. valida-porta.sh
**Conceitos:** validação de argumentos, teste de porta TCP, fallback com `nc`.

```bash
timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$porta" 2>/dev/null
```
- `/dev/tcp/HOST/PORT` é recurso do Bash (não arquivo real) para testar TCP.
- `timeout 2` impede travamento indefinido se host não responde.
- `nc -z -w 2` como fallback se `/dev/tcp` não funcionar (ex: Bash compilado sem).

---

## 3. monitor-servico.sh
**Conceitos:** `systemctl is-active`, `systemctl list-unit-files`, `case`.

```bash
estado=$(systemctl is-active "$servico" 2>/dev/null)
```
- `is-active` retorna: `active`, `inactive`, `failed`, `activating`, `deactivating`.
- Código de saída: 0 (active), 3 (inactive), 1 (failed), outros para transições.
- Verifica existência antes via `list-unit-files` para dar erro específico.

---

## 4. detecta-pkg.sh
**Conceitos:** `/etc/os-release`, `case` com múltiplos IDs por gerenciador.

```bash
source /etc/os-release
case "$ID" in
    ubuntu|debian|linuxmint|pop|elementary|zorin) echo "apt" ;;
    ...
esac
```
- Muitas derivadas compartilham o mesmo gerenciador.
- `source /etc/os-release` carrega variáveis `ID`, `VERSION_ID`, `PRETTY_NAME`, etc.

---

## 5. valida-backup.sh
**Conceitos:** Early Return completo, `du -sk`, `df -k`, cálculo de espaço com margem.

```bash
tamanho_origem_kb=$(du -sk "$origem" | awk '{print $1}')
livre_destino_kb=$(df -k "$destino" | awk 'NR==2 {print $4}')
minimo_kb=$(( tamanho_origem_kb * 2 ))
```
- `du -sk` = tamanho em KB (somatório recursivo).
- `df -k` = espaço livre em KB (coluna 4 da linha 2).
- Margem de 2x evita falha por metadados, journal, compressão temporária.

---

## 6. triagem-log.sh
**Conceitos:** `case` com conversão para maiúscula `${var^^}`, padrões curinga.

```bash
case "${linha^^}" in
    *ERROR*|*FATAL*|*CRITICAL*|*EXCEPTION*|*PANIC*) echo "CRÍTICO" ;;
    ...
esac
```
- `${var^^}` converte string toda para maiúscula (Bash 4.0+).
- Permite case-insensitive sem `shopt -s nocasematch`.
- Padrões `*PALAVRA*` detectam a palavra em qualquer posição.

---

## 7. checa-deps.sh
**Conceitos:** arrays, `command -v`, iteração sobre argumentos.

```bash
for cmd in "$@"; do
    if command -v "$cmd" >/dev/null; then
        encontrados+=("$cmd")
    else
        faltando+=("$cmd")
    fi
done
```
- `command -v` é o jeito POSIX correto de testar existência de comando.
- Arrays `encontrados` e `faltando` acumulam resultados.
- `${#array[@]}` = quantidade de elementos.

---

## 8. ferramenta.sh
**Conceitos:** subcomandos estilo CLI real, `case` para despacho, help padronizado.

```bash
subcomando="$1"
shift
case "$subcomando" in
    status) ... ;;
    limpa) ... ;;
    info) ... ;;
    ajuda) ... ;;
    *) exit 2 ;;
esac
```
- Padrão `shift` remove o subcomando de `$@`, deixando argumentos do subcomando.
- Cada subcomando pode ter seus próprios flags/argumentos.
- `ajuda|help|-h|--help` aceita múltiplas formas de pedir ajuda.
- Código 2 para uso incorreto (padrão Unix/Linux).

---

## Resumo de Padrões para SRE/Infra

| Situação | Padrão Recomendado |
|---|---|
| Validações de entrada | Early Return com `[[ cond ]] \|\| { echo >&2; exit N; }` |
| Múltiplos estados/valores de uma variável | `case "$var" in ... esac` |
| Verificar se comando existe | `command -v "cmd" >/dev/null` |
| Exigir root | `[[ $EUID -ne 0 ]] && { echo >&2; exit 1; }` |
| Detectar distro | `source /etc/os-release` + `case "$ID"` |
| Subcomandos CLI | `$1` + `shift` + `case` |
| Saída de erro | Sempre `>&2` |
| Códigos de saída | 0=OK, 1=erro genérico, 2=uso incorreto, 3+=específico |

> **Dica SRE:** Scripts de automação em produção **sempre** devem validar pré-condições e falhar explicitamente com mensagem clara e código de saída distinto. O sistema de monitoramento (cron, systemd, Prometheus) depende desses códigos para alertar corretamente.