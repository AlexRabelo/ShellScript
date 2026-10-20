# Cheat sheet de Bash

## Estrutura mínima

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "olá"
```

## Variáveis

```bash
nome="Ana"                 # sem espaços ao redor do =
echo "$nome"               # sempre entre aspas
echo "${nome}_backup"      # chaves para delimitar
export PATH="$HOME/bin:$PATH"
hoje="$(date +%F)"         # saída de comando
soma=$(( 3 + 4 ))          # aritmética
readonly VERSAO="1.0"
```

## Parâmetros

| Símbolo | Significado |
|---|---|
| `$0` | nome do script |
| `$1 … $9`, `${10}` | argumentos posicionais |
| `$#` | quantidade de argumentos |
| `"$@"` | todos os argumentos, cada um preservado |
| `$?` | código de saída do último comando |
| `$$` | PID do script |

## Valores padrão

```bash
"${var:-padrao}"           # usa padrao se var vazia ou indefinida
"${var:?mensagem}"         # aborta com mensagem se var vazia
"${var:=padrao}"           # atribui e usa
```

## Testes

```bash
[[ -e arq ]]  [[ -f arq ]]  [[ -d dir ]]  [[ -r arq ]]  [[ -x arq ]]  [[ -s arq ]]
[[ -z "$s" ]]  [[ -n "$s" ]]  [[ "$a" == "$b" ]]  [[ "$s" == pad* ]]  [[ "$s" =~ ^[0-9]+$ ]]
(( a > b ))   [ "$a" -eq "$b" ]   # -eq -ne -lt -le -gt -ge
```

## Decisão

```bash
if [[ condição ]]; then
    ...
elif [[ outra ]]; then
    ...
else
    ...
fi

case "$1" in
    start|iniciar) ... ;;
    stop)          ... ;;
    *)             echo "uso: $0 {start|stop}" >&2; exit 2 ;;
esac
```

## Laços

```bash
for i in {1..5}; do ...; done
for f in *.log; do ...; done
for ((i=0; i<5; i++)); do ...; done
while IFS= read -r linha; do ...; done < arquivo
until condição; do ...; done
```

## Funções

```bash
soma() {
    local a="$1" b="$2"
    echo $(( a + b ))
}
resultado="$(soma 2 3)"
```

## Arrays

```bash
lista=(web01 web02 db01)
echo "${lista[0]}"  "${#lista[@]}"
for h in "${lista[@]}"; do ...; done
declare -A porta=([ssh]=22 [http]=80)
echo "${porta[ssh]}"  "${!porta[@]}"
```

## Manipulação de strings

```bash
${var#prefixo}   ${var##prefixo}      # remove do início (menor / maior)
${var%sufixo}    ${var%%sufixo}       # remove do fim
${var/velho/novo}  ${var//velho/novo} # substitui (primeiro / todos)
${var^^}  ${var,,}  ${#var}  ${var:2:3}
```

## Redirecionamento

```bash
> arq    >> arq    < arq    2> erros    2>&1    &> tudo    > /dev/null 2>&1
comando1 | comando2          # pipe
comando <<< "texto"          # here-string
cat << 'EOF'                 # here-document (aspas = sem expansão)
...
EOF
```

## Combinação de comandos

```bash
a && b        # b só se a der certo
a || b        # b só se a falhar
a ; b         # sempre os dois
( a; b )      # subshell
{ a; b; }     # agrupamento no shell atual
```

## Depuração

```bash
bash -n script.sh      # só sintaxe
bash -x script.sh      # traça a execução
set -x ; ... ; set +x  # traça um trecho
shellcheck script.sh
```
