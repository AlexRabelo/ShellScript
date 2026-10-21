# Armadilhas clássicas

| # | Erro | Por que acontece | Correção |
|---|---|---|---|
| 1 | `var = "x"` | O shell tenta executar o comando `var` | `var="x"` (sem espaços) |
| 2 | `rm -rf $DIR/*` | Se `DIR` estiver vazia vira `rm -rf /*` | `rm -rf -- "${DIR:?}"/*` e `set -u` |
| 3 | `cp $arq destino` | Espaços no nome quebram em dois argumentos | `cp "$arq" destino` |
| 4 | `for f in $(ls)` | Quebra nomes com espaço | `for f in *` |
| 5 | `cat arq \| while read l; do n=1; done; echo $n` | O `while` com pipe roda em subshell | `while ...; done < arq` |
| 6 | `[ $a = $b ]` | Variável vazia gera erro de sintaxe | `[[ "$a" == "$b" ]]` |
| 7 | `[ "$a" > "$b" ]` | `>` vira redirecionamento e cria arquivo | `[[ "$a" > "$b" ]]` ou `(( ))` para números |
| 8 | `cd dir; rm -rf *` | Se o `cd` falhar, apaga o diretório errado | `cd dir \|\| exit 1` ou `set -e` |
| 9 | `comando \| outro` ignorando erro do primeiro | Pipe devolve só o código do último | `set -o pipefail` |
| 10 | `echo $?` depois de outro comando | O `$?` já foi sobrescrito | `codigo=$?` logo após o comando |
| 11 | `a && b \|\| c` como se fosse `if` | `c` roda também se `b` falhar | Use `if ... then ... else` |
| 12 | Script editado no Windows | Fim de linha CRLF: `bad interpreter ^M` | `sed -i 's/\r$//'` / `.gitattributes` com `eol=lf` |
| 13 | `sed -i` sem backup | Sem volta | `sed -i.bak ...` ou versione o arquivo |
| 14 | `eval "$entrada"` | Execução arbitrária de código | Evite `eval`; valide e use arrays |
| 15 | Senhas em argumentos (`mysql -pSENHA`) | Visíveis em `ps` e no histórico | Arquivo de credenciais `600` ou variável de ambiente |
| 16 | `cron` sem `PATH` completo | Ambiente mínimo | Caminhos absolutos ou defina `PATH` no topo |
| 17 | Dois cron sobrepostos | Execução anterior ainda rodando | `flock -n` |
| 18 | `uniq` sem `sort` | Só junta linhas adjacentes | `sort \| uniq -c` |
| 19 | `$*` entre aspas | Une tudo em uma única string | `"$@"` |
| 20 | Usar `echo` com `-e` e `-n` em scripts portáveis | Comportamento varia entre shells | `printf` |

## Regra de ouro

> **Dúvida entre usar ou não aspas? Use aspas.** `"$variavel"`, `"$(comando)"`, `"${array[@]}"`.

## Antes de rodar em produção

1. `shellcheck script.sh`
2. `bash -n script.sh`
3. Rode com `--dry-run`
4. Teste em ambiente de laboratório
5. Leia o script como se outra pessoa o tivesse escrito
