# Gabarito e Explicações: Módulo 08

## 1. top-status.sh
**Conceitos:** `awk` extrai coluna, `sort | uniq -c | sort -rn`, `LC_ALL=C`.

```bash
LC_ALL=C awk '{print $9}' "$ARQUIVO" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -rn
```
- `LC_ALL=C` força locale C (ordem de bytes), acelera `sort` em 5-10x.
- Pipeline padrão de frequência.

---

## 2. erros-hora.sh
**Conceitos:** Arrays associativos `declare -A`, regex `=~` com `BASH_REMATCH`, gráfico ASCII proporcional.

```bash
[[ "$linha" =~ T([0-9]{2}): ]] && hora="${BASH_REMATCH[1]}"
(( contagem["$hora"]++ ))
```
- `=~` captura grupos em `BASH_REMATCH[1]`, `BASH_REMATCH[2]`, etc.
- Gráfico: `barras = count * 40 / max` normaliza para 40 chars.

---

## 3. ips-ssh.sh
**Conceitos:** `journalctl` fallback, regex para extrair IP, `grep -oE`.

```bash
grep -E "Failed password|Invalid user" "$ARQUIVO" | \
grep -oE 'from [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
sed 's/from //'
```
- `grep -oE` imprime apenas o trecho que casa com a regex.
- `sed 's/from //` remove o prefixo "from ".

---

## 4. altera-porta.sh
**Conceitos:** `sed -i` com backup timestamp, delimitador `#`, `diff -u`.

```bash
sed -i "s#^\([[:space:]]*${CHAVE}[[:space:]]*[=:][[:space:]]*\).*#\1${VALOR}#" "$ARQUIVO"
```
- Delimitador `#` evita escape de `/` em caminhos/URLs.
- `\(...\)` captura grupo (chave + separador + espaços) → `\1` reusa no replacement.
- `diff -u` mostra unified diff legível.

---

## 5. conexoes.sh
**Conceitos:** `ss` vs `netstat`, `awk` com `match()` e regex, `column -t`.

```bash
ss -tunlp | awk 'match($5, /([^:]+):([0-9]+)$/, m) { ip=m[1]; port=m[2] }'
```
- `ss -tunlp`: tcp, udp, numeric, listening, processes.
- `match(str, regex, array)` popula array com grupos de captura (GNU awk).

---

## 6. cpu-processo.sh
**Conceitos:** `ps -p PID -o %cpu=`, `awk` para float, gráfico ASCII, loop com `kill -0`.

```bash
cpu=$(ps -p "$PID" -o %cpu=)
barras=$(awk -v c="$cpu" 'BEGIN {print int(c/2)}')
```
- `kill -0 PID` testa se processo existe sem enviar sinal.
- `awk` faz aritmética float (Bash não faz).

---

## 7. parse-json.sh
**Conceitos:** `jq` básico: `.[]`, `select`, `max_by`, `add / length`.

```bash
jq '[.[] | .cpu] | add / length'       # média
jq 'max_by(.cpu) | .host'              # host do máximo
jq -r '.[] | select(.cpu > 70) | .host' # filtro
```
- `[]` itera array.
- `select()` filtra objetos.
- `-r` saída raw (sem aspas).

---

## 8. dedup-logs.sh
**Conceitos:** `awk '!seen[$0]++'` preserva ordem, `sort | uniq -d` mostra duplicatas.

```bash
awk '!seen[$0]++' arquivo
```
- `seen[$0]` é 0 na primeira ocorrência → `!0` = verdadeiro → imprime.
- Nas próximas, `seen[$0]` > 0 → `!verd` = falso → não imprime.
- **Preserva ordem original** (diferente de `sort | uniq`).

---

## 9. csv-servidores.sh
**Conceitos:** `awk -F,`, trim de campos, agregação por chave.

```bash
awk -F, '
    NR==1 { next }
    { gsub(/^[ \t]+|[ \t]+$/, "", $3); amb=$3; count[amb]++; total_cpu[amb]+=$4 }
    END { for (a in count) print a, count[a], total_cpu[a] }
'
```
- `-F,` define vírgula como separador de campos.
- `gsub` remove espaços nos campos.
- Agrega em arrays indexados por string (`amb`).

---

## 10. latencia-http.sh
**Conceitos:** `curl -w` com métricas, arrays, percentil P95, histograma.

```bash
curl -w "connect=%{time_connect} starttransfer=%{time_starttransfer} total=%{time_total} http=%{http_code}"
p95_idx=$(( count * 95 / 100 ))
p95=${sorted[p95_idx]}
```
- `time_connect`: TCP handshake.
- `time_starttransfer`: primeiro byte (TTFB).
- `time_total`: tempo total.
- P95: ordena e pega índice 95%.

---

## Resumo de Ferramentas para SRE

| Ferramenta | Caso de Uso Principal |
|---|---|
| `grep -E` | Busca múltipla (ex: erro OU falha) |
| `grep -o` | Extrai apenas o trecho (ex: IP, email) |
| `awk '{print $1}'` | Extrai coluna fixa |
| `awk -F:` | Delimitador customizado |
| `awk 'END {print soma}'` | Agregação numérica |
| `sed -i.bak 's/a/b/'` | Edição in-place com backup |
| `sort \| uniq -c \| sort -rn` | Top N frequências |
| `awk '!seen[$0]++'` | Dedup preservando ordem |
| `jq '[.[] | .cpu] | add/length` | Média em JSON |
| `column -t` | Alinha colunas em tabela |

> **Dica de Performance SRE:** Para arquivos grandes (>100MB), use `LC_ALL=C` antes de `sort`/`grep`/`awk`. Evita overhead de locale UTF-8 e acelera 5-10x.