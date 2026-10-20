# Gabarito e Explicações: Módulo 05

## 1. tabuada.sh
**Conceitos:** `for` com sequência `{1..10}`, aritmética `$(( ))`.

```bash
for i in {1..10}; do
    echo "$num x $i = $(( num * i ))"
done
```
- Bash expande `{1..10}` antes de executar o laço.
- `i` recebe cada valor da expansão.

---

## 2. conta-erros.sh
**Conceitos:** `while IFS= read -r`, case-insensitive com `${var^^}`.

```bash
while IFS= read -r linha; do
    if [[ "${linha^^}" == *ERROR* || "${linha^^}" == *ERRO* ]]; then
        (( contador++ ))
    fi
done < "$arquivo"
```
- `IFS=` preserva espaços no início/fim.
- `-r` preserva barras invertidas.
- `${linha^^}` converte para maiúscula (case-insensitive nativo).

---

## 3. retry-http.sh
**Conceitos:** Retry loop, `curl` com flags de monitoramento, backoff fixo.

```bash
while (( tentativa < max_tentativas )); do
    (( tentativa++ ))
    saida=$(curl -f -s -S -o /dev/null -w "HTTP=%{http_code} TIME=%{time_total}s" --max-time 10 "$url" 2>&1)
    ...
    sleep "$intervalo"
done
```
- `curl -f`: falha (exit != 0) em HTTP >= 400.
- `-w "HTTP=%{http_code} TIME=%{time_total}s"`: extrai métricas sem depender de stdout.
- `--max-time 10`: timeout total da requisição (evita travamento).

---

## 4. processa-servidores.sh
**Conceitos:** Arrays associativos `declare -A`, CSV parsing com `IFS=','`, ping test.

```bash
declare -A total_por_amb
declare -A online_por_amb
while IFS=',' read -r nome ip ambiente role; do
    ...
    (( total_por_amb[$ambiente]++ ))
    ...
done < "$arquivo"
```
- `IFS=','` define vírgula como separador para `read`.
- Arrays associativos permitem contadores indexados por string (nome do ambiente).
- `"${!array[@]}"` itera sobre as chaves do array associativo.

---

## 5. limpeza-segura.sh
**Conceitos:** `find -print0` + `read -r -d ''`, confirmação interativa, `numfmt`.

```bash
while IFS= read -r -d '' arquivo; do
    ...
done < <(find "$diretorio" -type f -name "$padrao" -mtime "+$dias" -print0)
```
- `-print0` usa NUL (`\0`) como separador (seguro para qualquer nome de arquivo).
- `read -r -d ''` lê até o NUL.
- Process substitution `< <(comando)` evita subshell do pipe.

---

## 6. monitora-processo.sh
**Conceitos:** Loop infinito `while true`, `pgrep -c`, `trap INT`, beep `\a`.

```bash
trap 'echo; echo "Monitoramento interrompido."; exit 0' INT
while true; do
    count=$(pgrep -c "$processo" 2>/dev/null || echo 0)
    ...
    sleep "$intervalo"
done
```
- `pgrep -c` conta processos pelo nome (mais rápido que `ps | grep`).
- `trap INT` captura Ctrl+C para saída limpa.
- `echo -e '\a'` emite beep do terminal (ASCII BEL).

---

## 7. deploy-hosts.sh
**Conceitos:** SSH em lote, flags de automação (`BatchMode`, `ConnectTimeout`, `StrictHostKeyChecking`), captura de saída remota.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$host" "$comando"
```
- `BatchMode=yes`: falha se precisar de senha (requer chave SSH configurada).
- `ConnectTimeout=5`: timeout de conexão TCP (não do comando remoto).
- `StrictHostKeyChecking=no`: aceita host keys automaticamente (apenas lab!).

---

## 8. aguarda-lock.sh
**Conceitos:** `flock -n` (não-bloqueante), `until`, file descriptor.

```bash
exec 9>"$lockfile"
until flock -n 9; do
    sleep 2
done
```
- `exec 9>"$lockfile"` abre FD 9 para o arquivo (cria se não existe).
- `flock -n 9`: tenta lock exclusivo, falha imediatamente se ocupado (exit 1).
- `until flock -n 9; do ... done`: repete até conseguir o lock.
- Lock é liberado automaticamente ao sair (FD 9 fechado).

---

## 9. filtra-servidores.sh
**Conceitos:** `continue` (pula iteração), `break` (sai do laço), array de exceção.

```bash
for entrada in "${SERVIDORES[@]}"; do
    if [[ " ${MANUTENCAO[*]} " == *" $nome "* ]]; then
        continue
    fi
    ...
    if (( offline_consecutivos >= 3 )); then
        break
    fi
done
```
- `continue`: pula direto para próxima iteração do `for`.
- `break`: sai completamente do laço mais interno.
- `" ${MANUTENCAO[*]} " == *" $nome "*`: teste de pertinência em array (com espaços para evitar match parcial).

---

## 10. ping-paralelo.sh
**Conceitos:** `xargs -P` para paralelismo, substituição `-I {}`, comparação de tempo.

```bash
cat "$arquivo" | xargs -P 10 -I {} bash -c 'ping -c 1 -W 1 "{}" >/dev/null 2>&1 && echo "{}"'
```
- `-P 10`: até 10 processos simultâneos.
- `-I {}`: define placeholder para cada linha de entrada.
- `bash -c '...'`: executa comando complexo com redirecionamentos.
- Speedup típico: 5-10x mais rápido que sequencial para latência de rede.

---

## Padrões SRE para Laços em Produção

| Cenário | Padrão Recomendado |
|---|---|
| Lista conhecida de itens | `for item in "${ARRAY[@]}"; do` |
| Sequência numérica | `for i in {1..N}` ou `for ((i=1; i<=N; i++))` |
| Arquivo linha a linha | `while IFS= read -r linha; do ... done < arquivo` |
| Arquivos com glob | `for f in *.log; do` (nunca `$(ls)`) |
| Esperar condição (retry) | `until comando; do sleep; done` com contador limite |
| Esperar lock | `until flock -n FD; do sleep; done` |
| Processar saída de comando | `while IFS= read -r; do ... done < <(comando)` |
| Paralelismo simples | `xargs -P N -I {} comando {}` |
| Nomes com espaços/estranhos | `find -print0 \| while IFS= read -r -d ''` |

> **Regra de Ouro SRE:** Todo laço que executa ação externa (SSH, curl, ping, API) **deve** ter timeout, limite de tentativas e logging de progresso. Laços infinitos sem saída são bugs de produção.