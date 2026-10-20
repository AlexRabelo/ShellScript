# Módulo 09: Arrays e Expansões — Manipulação Nativa de Strings

> **Analogia:** Arrays são **listas ordenadas** (índice 0,1,2...). Arrays associativos são **dicionários** (chave → valor). Expansões de parâmetro são **ferramentas de corte e costura** nativas — fazem em 1 linha o que `sed`/`awk` fariam em 10.

## Objetivos

Ao final deste módulo você será capaz de:

- Criar, modificar, fatiar e iterar arrays indexados e associativos
- Usar expansões de parâmetro: `${var#prefixo}`, `${var%sufixo}`, `${var//busca/sub}`, `${var^^}`, `${var,,}`, `${var:pos:len}`
- Entender `IFS` e `read -a` / `mapfile` para ler em array
- Usar `declare -p` para inspecionar estrutura
- Evitar armadilhas: `$(cmd)` vs `$(cmd)` em array, globbing acidental

---

## 1. Arrays indexados — recapitulação + avançado

```bash
arr=(a b c d e)
arr[5]=f              # índice explícito
arr+=(g h)            # append
unset arr[2]          # remove índice 2 (buraco!)
echo "${arr[@]}"      # a b d e f g h  (índice 2 sumiu)
echo "${!arr[@]}"     # 0 1 3 4 5 6  (índices reais)
echo "${#arr[@]}"     # 7 elementos

# Iteração segura (respeita buracos)
for i in "${!arr[@]}"; do
    echo "[$i] = ${arr[i]}"
done
```

---

## 2. Arrays associativos — `declare -A`

```bash
declare -A cores=( ["vermelho"]="#FF0000" ["verde"]="#00FF00" )
cores["azul"]="#0000FF"
unset cores["verde"]

for cor in "${!cores[@]}"; do
    echo "$cor -> ${cores[$cor]}"
done
```

---

## 3. Expansões de parâmetro — a faca suíça

| Expansão | Efeito | Exemplo |
|----------|--------|---------|
| `${var#pat}` | Remove **menor** prefixo | `${path#*/}` → remove até 1º `/` |
| `${var##pat}` | Remove **maior** prefixo | `${path##*/}` → **basename** |
| `${var%pat}` | Remove **menor** sufixo | `${file%.txt}` → remove `.txt` |
| `${var%%pat}` | Remove **maior** sufixo | `${path%%/*}` → **dirname** |
| `${var/old/new}` | Substitui **1ª** ocorrência | `${str/ /_}` |
| `${var//old/new}` | Substitui **todas** | `${str// /_}` |
| `${var^}` | 1ª letra maiúscula | `"bash"^` → `Bash` |
| `${var^^}` | **Todas** maiúsculas | `"bash"^^` → `BASH` |
| `${var,}` | 1ª letra minúscula | `"BASH",` → `bASH` |
| `${var,,}` | **Todas** minúsculas | `"BASH",,` → `bash` |
| `${var:pos:len}` | Substring (índice:tamanho) | `${str:2:3}` |
| `${#var}` | Comprimento | `${#str}` |

---

## 4. IFS e leitura em array

```bash
# IFS default: espaço, tab, newline
linha="a:b:c"
IFS=: read -r -a arr <<< "$linha"
# arr=(a b c)

# mapfile (bash 4+) — lê arquivo inteiro em array
mapfile -t linhas < arquivo.txt
# -t: remove newline final
```

---

## 5. Inspeção e debugging

```bash
declare -p arr        # mostra declaração completa: typeset -a arr=([0]="a" [1]="b")
declare -p assoc      # typeset -A assoc=([chave]="valor" ...)
```

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| `for i in ${arr[@]}` | Sem aspas → word splitting + globbing | **Sempre** `"${arr[@]}"` |
| `arr=( $(cmd) )` | Quebra saída de cmd em palavras | `mapfile -t arr < <(cmd)` ou `readarray` |
| `unset arr` apaga tudo | `unset arr[2]` apaga só índice | Use índice explícito |
| Expansão `#%` não funciona | Pattern é glob, não regex | Use `*` `?` `[...]` no pattern |
| `${var^^}` não existe | Bash < 4 | `bash --version`; use `tr 'a-z' 'A-Z'` |

---

## Prática

### Exemplos conceituais
- [`exemplos/conceito-arrays.sh`](exemplos/conceito-arrays.sh) — indexados, associativos, buracos
- [`exemplos/conceito-expansoes.sh`](exemplos/conceito-expansoes.sh) — # ## % %% // ^^ ,, : :
- [`exemplos/conceito-ifs-mapfile.sh`](exemplos/conceito-ifs-mapfile.sh) — IFS, read -a, mapfile

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 6 exercícios + autoavaliação.

---

## Autoavaliação

- [ ] Sei criar/iterar arrays indexados e associativos, lidar com buracos
- [ ] Sei usar `${var#pat}`, `${var##pat}`, `${var%pat}`, `${var%%pat}` para paths
- [ ] Sei `${var//busca/sub}`, `${var^^}`, `${var,,}`, `${var:pos:len}`
- [ ] Sei ler arquivo em array com `mapfile -t` e `IFS=: read -a`
- [ ] Sei inspecionar com `declare -p`

Se marcou todos, siga para o [Módulo 10](../10-scripts-de-producao/).