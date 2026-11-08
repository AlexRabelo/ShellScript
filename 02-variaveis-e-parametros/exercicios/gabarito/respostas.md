# Gabarito e Explicações: Módulo 02

## 1. soma-media.sh
**Conceitos:** parâmetros posicionais, validação com regex, aritmética `$(( ))`, `awk` para decimal.

```bash
[[ $# -eq 2 ]] || { echo "Uso: $0 NUM1 NUM2" >&2; exit 2; }
[[ "$a" =~ ^-?[0-9]+$ ]] || { echo "Erro: '$a' não é um número inteiro" >&2; exit 1; }
```
- `$#` verifica quantidade de argumentos.
- `=~` com regex valida inteiro (inclui negativo com `-?`).
- `awk` resolve a divisão decimal: `awk "BEGIN { printf \"%.1f\", ($a + $b) / 2 }"`.

## 2. lista-args.sh
**Conceitos:** `$0`, `$#`, `"$@"` vs `$*`, laço `for`.

```bash
for arg in "$@"; do ... done
```
- `"$@"` (com aspas) preserva cada argumento como palavra separada.
- `$*` (sem aspas) junta todos com IFS e faz word splitting.

## 3. cria-dir-data.sh
**Conceitos:** `read -p`, valor padrão `${var:-padrao}`, `date +%F`, `mkdir -p`.

```bash
destino="${destino:-/tmp}"
data="$(date +%F)"
mkdir -p "$dir_completo"
```
- `${var:-padrao}` usa o padrão se variável vazia ou indefinida.
- `date +%F` = `YYYY-MM-DD` (ISO 8601).
- `mkdir -p` cria pais e não erra se já existir.

## 4. valores-padrao.sh
**Conceitos:** valores padrão para múltiplos argumentos.

```bash
arquivo="${1:-dados.txt}"
diretorio="${2:-/tmp}"
prefixo="${3:-bkp}"
```
- Cada argumento tem seu padrão independente.
- Útil para scripts com parâmetros opcionais.

## 5. expansao-param.sh
**Conceitos:** expansão de parâmetros `%`, `%%`, `#`, `##`.

| Operação | Sintaxe | Remove |
|----------|---------|--------|
| Sufixo curto | `${var%pattern}` | Do final, menor match |
| Sufixo longo | `${var%%pattern}` | Do final, maior match |
| Prefixo curto | `${var#pattern}` | Do início, menor match |
| Prefixo longo | `${var##pattern}` | Do início, maior match |

```bash
dir_pai="${caminho%/*}"        # remove /arquivo.ext → diretório
nome_com_ext="${caminho##*/}"  # remove /pasta/ → arquivo.ext
extensao="${nome_com_ext##*.}" # remove nome. → ext
nome_sem_ext="${nome_com_ext%.*}" # remove .ext → nome
```

## 6. confirma-senha.sh
**Conceitos:** `read -sp` (silencioso), comparação de strings `[[ "$a" == "$b" ]]`.

```bash
read -sp "Senha: " senha1
echo  # pula linha porque -s não ecoa o \n
```
- `-s` não mostra a digitação (ideal para senhas).
- `echo` após `read -s` força a quebra de linha no terminal.

## 7. backup-v2.sh
**Conceitos:** substituição de comando `$(date ...)`, expansão de parâmetros, `du -h`.

```bash
timestamp="$(date +%Y%m%d-%H%M%S)"
backup="${destino}/${nome_sem_ext}-${timestamp}.${extensao}"
```
- `date +%Y%m%d-%H%M%S` = `20261012-143052` (compacto, ordenável).
- `du -h` mostra tamanho legível (K, M, G).

## 8. mostra-env.sh
**Conceitos:** `printenv`, variáveis de ambiente, código de saída.

```bash
if printenv "$var_nome" >/dev/null 2>&1; then
    printenv "$var_nome"
else
    echo "Variável não definida" >&2
    exit 1
fi
```
- `printenv` retorna 0 se variável existe, 1 se não.
- Redireciona saída para `/dev/null` no teste, imprime só se existir.
- Alternativa Bash: `declare -n ref="$var_nome"` (expansão indireta).

## 9. contador.sh
**Conceitos:** `for (( ))` estilo C, aritmética `(( soma += i ))`.

```bash
for (( i = inicial; i <= limite; i++ )); do
    (( soma += i ))
done
```
- `for (( init; cond; inc ))` é sintaxe C, só funciona em `(( ))`.
- Variáveis dentro de `(( ))` não precisam de `$`.

## 10. define-var.sh + teste-source.sh
**Conceitos:** `source` vs execução normal, escopo de variáveis.

```bash
source ./define-var.sh   # roda no shell ATUAL -> minha_var persiste
bash ./define-var.sh     # roda em SUBSHELL -> minha_var morre no fim
```

| Forma | Processo | Variáveis persistem? |
|-------|----------|---------------------|
| `source script.sh` | Atual | **Sim** |
| `. script.sh` | Atual | **Sim** |
| `./script.sh` | Filho | Não |
| `bash script.sh` | Filho | Não |

> **Use `source`** para carregar bibliotecas de funções (módulo 06).
> **Use execução normal** para scripts independentes.