# Exercícios: Módulo 08 — Processamento de Texto

Crie os scripts em `~/ex08/`. Consulte o [gabarito](gabarito/) só depois de tentar.

---

## Exercícios

### 1. Filtro de log com grep
**Arquivo:** `filtra-log.sh`
- Receba `$1` (arquivo de log) e `$2` (padrão)
- Use `grep -n -E` para mostrar linhas com número
- Se `$2` vazio, use padrão default: `ERRO|ERROR|WARN|WARNING`
- Imprima total de ocorrências no final (`grep -c`)

### 2. Normalizador de CSV com sed
**Arquivo:** `normaliza-csv.sh`
- Receba `$1` (arquivo CSV com `;` como separador)
- Converta para CSV padrão (`,` separador, aspas nos campos)
- Trate: `;` → `,`, remova espaços ao redor, adicione aspas se campo tem vírgula/aspas
- Imprima resultado no stdout

### 3. Relatório de acesso com awk
**Arquivo:** `relatorio-acesso.sh`
- Receba `$1` (access.log formato combined)
- Imprima:
  - Total de requisições
  - Top 5 IPs por contagem
  - Top 5 IPs por bytes transferidos
  - Códigos de resposta e contagem (200, 301, 404, 500, etc.)
  - Requisições por hora (extraia hora do timestamp)

### 4. Extrai IPs únicos com pipeline
**Arquivo:** `extrai-ips.sh`
- Receba `$1` (arquivo qualquer)
- Use `grep -oE` para extrair padrões IPv4
- `sort -u` para únicos
- Imprima um por linha

### 5. Conta palavras (wc style) com awk
**Arquivo:** `conta-palavras.sh`
- Receba `$1` (arquivo texto)
- Imprima: linhas, palavras, caracteres (como `wc`)
- Use `awk` (não `wc`)

### 6. Parse de key=value com awk
**Arquivo:** `parse-kv.sh`
- Receba `$1` (arquivo com linhas `chave=valor`)
- Ignore linhas vazias e começando com `#`
- Imprima JSON: `{"chave": "valor", ...}`
- Use `awk` para construir JSON

---

## Autoavaliação

- [ ] Sei `grep -E`, `-v`, `-i`, `-c`, `-n`, `-A/-B/-C`, `-o`
- [ ] Sei `sed s///g`, `d`, `-n p`, delimitadores alternativos
- [ ] Sei `awk` `$1`, `FS/OFS`, `NR/NF`, `BEGIN/END`, arrays associativos
- [ ] Sei combinar `grep | sed | awk` em pipeline útil
- [ ] Sei escolher ferramenta: grep (filtra), sed (transforma), awk (processa colunas)

Se marcou todos, siga para o [Módulo 09](../09-arrays-e-expansoes/).