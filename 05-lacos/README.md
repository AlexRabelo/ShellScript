# Módulo 05: Laços — for, while, until

> **Analogia:** laço é uma **esteira de fábrica** — a peça (dado) entra, passa por estações (comandos), sai transformada. `for` sabe quantas peças; `while`/`until` processa até a condição mudar.

## Objetivos

Ao final deste módulo você será capaz de:

- Escrever `for` sobre listas, arrays, sequências numéricas, globs e saída de comandos
- Escrever `while` com condição de teste (`[[ ]]`, `(( ))`, comando)
- Escrever `until` (inverso do `while`)
- Controlar fluxo com `break` (sai do laço) e `continue` (pula para próxima iteração)
- Ler arquivos linha a linha com `while IFS= read -r`
- Implementar retry loop com backoff e timeout

---

## 1. for — iteração conhecida

```bash
# Lista explícita
for fruta in maçã banana laranja; do
    echo "Fruta: $fruta"
done

# Array (use "${arr[@]}" com aspas!)
servidores=("web01" "web02" "db01")
for s in "${servidores[@]}"; do
    echo "Verificando $s"
done

# Sequência numérica
for i in {1..5}; do
    echo "Número $i"
done
for (( i=0; i<5; i++ )); do    # estilo C
    echo "Índice $i"
done

# Globs (arquivos)
for arquivo in *.log; do
    [[ -f "$arquivo" ]] || continue
    echo "Processando $arquivo"
done

# Saída de comando (CUIDADO: word splitting!)
# Melhor: mapfile ou while read
for usuario in $(cut -d: -f1 /etc/passwd); do
    echo "User: $usuario"
done
```

> **Regra de ouro:** Iterar arrays **sempre** com `"${arr[@]}"`. Iterar saída de comando **evite** `for x in $(cmd)` — use `while IFS= read -r` ou `mapfile`.

---

## 2. while — condição verdadeira

```bash
# Contador
contador=0
while (( contador < 5 )); do
    echo "Contador: $contador"
    ((contador++))
done

# Lendo arquivo linha a linha (PADRÃO SEGURO)
while IFS= read -r linha; do
    echo "Linha: $linha"
done < /etc/passwd

# Loop infinito com break
while true; do
    read -p "Digite 'sair' para encerrar: " cmd
    [[ "$cmd" = "sair" ]] && break
    echo "Você digitou: $cmd"
done
```

---

## 3. until — condição falsa (inverso do while)

```bash
# Aguarda arquivo aparecer
until [[ -f /tmp/pronto ]]; do
    echo "Aguardando..."
    sleep 1
done
echo "Arquivo chegou!"
```

---

## 4. break e continue

```bash
for i in {1..10}; do
    (( i == 3 )) && continue   # pula 3
    (( i == 8 )) && break      # para no 8
    echo $i
done
# Imprime: 1 2 4 5 6 7
```

---

## 5. Retry loop com backoff (padrão produção)

```bash
tentativa=0
max_tentativas=5
until (( tentativa >= max_tentativas )); do
    ((tentativa++))
    if comando_que_pode_falhar; then
        echo "Sucesso na tentativa $tentativa"
        break
    fi
    pausa=$(( tentativa * 2 ))  # backoff linear: 2, 4, 6, 8...
    echo "Falhou. Tentativa $tentativa. Aguardando ${pausa}s..."
    sleep "$pausa"
done
(( tentativa >= max_tentativas )) && echo "Todas falharam" && exit 1
```

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `for f in $(ls)` | Quebra com espaços, globbing | `for f in *` ou `mapfile` |
| Variável não atualiza no while | Pipe cria subshell | `while ...; done < arquivo` (redirecionamento, não pipe) |
| Loop infinito acidental | Esqueceu de incrementar/controle | Sempre tenha condição de saída clara |
| `break` sai do `case`, não do `for` | `break` dentro de `case` no `for` | Use `break 2` ou refatore |

---

## Prática

### Exemplos
- [`exemplos/espera-servico.sh`](exemplos/espera-servico.sh) — retry loop com timeout e backoff
- [`exemplos/limpa-logs.sh`](exemplos/limpa-logs.sh) — for sobre glob + find + dry-run
- [`exemplos/processa-inventario.sh`](exemplos/processa-inventario.sh) — while read linha a linha
- [`exemplos/lista-servidores.sh`](exemplos/lista-servidores.sh) — for sobre array

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 10 exercícios progressivos + autoavaliação.

---

## Autoavaliação

- [ ] Sei iterar array com `"${arr[@]}"` e sequência com `{1..5}` / `(( ))`
- [ ] Sei ler arquivo com `while IFS= read -r` (redirecionamento, não pipe)
- [ ] Sei diferença entre `while` (enquanto verdadeiro) e `until` (enquanto falso)
- [ ] Sei usar `break` (sai) e `continue` (pula)
- [ ] Sei implementar retry com backoff e limite de tentativas
- [ ] Sei por que `for f in $(cmd)` é perigoso

Se marcou todos, siga para o [Módulo 06](../06-funcoes/).