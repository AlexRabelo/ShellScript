# Gabarito e Explicações: Módulo 03

## 1. verifica-dir.sh
**Conceitos:** testes de arquivo `-e`, `-d`, `-w`, código de saída.

```bash
[[ -e "$caminho" ]]   # existe
[[ -d "$caminho" ]]   # é diretório
[[ -w "$caminho" ]]   # gravável
```
- Variável entre aspas `"$caminho"` previne erros com espaços.
- Acumula falhas em variável `ok` e sai com código apropriado.

## 2. valida-numero.sh
**Conceitos:** regex `=~`, teste numérico `-eq`.

```bash
[[ "$num" =~ ^[0-9]+$ ]]   # apenas dígitos (sem sinal)
[[ $num -eq 0 ]]           # zero não é positivo
```
- `^[0-9]+$` = uma ou mais dígitos do início ao fim.
- Não usa `-gt 0` diretamente porque a variável pode não ser número; valida regex primeiro.

## 3. checa-arquivo.sh
**Conceitos:** `-f` (arquivo regular), `-s` (não vazio), `-r` (legível), códigos de saída específicos.

```bash
[[ ! -f "$caminho" ]]  # não é arquivo regular
[[ ! -s "$caminho" ]]  # vazio
[[ ! -r "$caminho" ]]  # não legível
```
- Cada falha tem código diferente (1, 2, 3) para automação saber o que aconteceu.
- Ordem importa: testa existência/tipo primeiro, depois conteúdo, depois permissão.

## 4. classifica.sh
**Conceitos:** `if/elif/else` (antecipando módulo 04), `(( ))` para aritmética.

```bash
(( num > 0 ))           # positivo
(( num % 2 == 0 ))      # par (resto da divisão por 2)
(( num >= 0 && num <= 10 ))  # range
```
- `(( ))` permite operadores C: `>`, `<`, `>=`, `<=`, `==`, `!=`, `%`, `&&`, `||`.
- Não precisa de `$` nas variáveis dentro de `(( ))`.

## 5. case-padrao.sh
**Conceitos:** `case` com padrões (curingas), múltiplos padrões com `|`.

```bash
case "$entrada" in
    erro*|ERRO*|Error*|error*)  nivel="CRÍTICO" ;;
    aviso*|AVISO*|Warning*)     nivel="ATENÇÃO" ;;
    info*|INFO*)                nivel="INFORMATIVO" ;;
    *)                          nivel="DESCONHECIDO" ;;
esac
```
- `*` no final = "começa com".
- `|` separa alternativas (OU).
- `*)` = padrão default (qualquer outro).

## 6. usuario-valido.sh
**Conceitos:** `id`, `getent passwd`, `cut`, testes de arquivo, comandos externos.

```bash
id "$usuario" >/dev/null 2>&1           # usuário existe?
getent passwd "$usuario" | cut -d: -f7  # shell do usuário
getent passwd "$usuario" | cut -d: -f6  # home do usuário
```
- `id` retorna 0 se usuário existe, 1 se não.
- `getent passwd` consulta NSS (funciona com LDAP, não só /etc/passwd).
- `cut -d: -f7` pega o 7º campo (shell) separado por `:`.
- Testa shell inválido (`nologin`, `false`) e existência/gravabilidade do home.

## 7. checa-comandos.sh
**Conceitos:** `command -v`, laço `for`, contadores, código de saída final.

```bash
for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then ...
done
```
- `command -v` é o jeito POSIX de testar se comando existe (melhor que `which`).
- Conta sucessos e falhas, sai com 0 se todos OK.

## 8. valida-formato.sh
**Conceitos:** `case` para dispatch, regex `=~` complexas, validação numérica extra.

```bash
# Email
^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$

# IP com validação de octetos
IFS='.' read -r o1 o2 o3 o4 <<< "$valor"
(( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 ))

# Data YYYY-MM-DD
IFS='-' read -r ano mes dia <<< "$valor"
(( mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31 ))

# Porta
[[ "$valor" =~ ^[0-9]+$ ]] && (( valor >= 1 && valor <= 65535 ))
```
- Regex valida formato, aritmética valida ranges.
- `IFS` + `read` + `<<<` (here-string) para split por delimitador.

## 9. curto-circuito.sh
**Conceitos:** funções, `&&` `||`, curto-circuito, por que não substitui `if`.

```bash
sucesso && falha && echo "A" || echo "B"
# 1. sucesso -> 0, continua
# 2. falha -> 1, PARA (curto-circuito do &&)
# 3. || captura o 1 e executa B
# A NUNCA roda!
```

**Tabela verdade do `A && B || C`:**

| A | B | C roda? | Equivale a if? |
|---|---|---------|----------------|
| 0 | 0 | Não | if A; then if B; then ... else C; fi |
| 0 | 1 | **Sim** | **DIFERENTE!** if A; then if B; then ... else C; fi (C não roda) |
| 1 | - | **Sim** | if A; then ... else C; fi |

> **Regra:** `&&` `||` é para encadear comandos onde o segundo depende do primeiro, NÃO para lógica if-else.

## 10. teste-portavel.sh
**Conceitos:** diferenças críticas entre `[[ ]]` e `[ ]`.

| Cenário | `[[ ]]` | `[ ]` |
|---------|---------|-------|
| Variável vazia | OK | Quebra sem aspas |
| Variável com espaços | OK | Quebra sem aspas |
| `5 < 10` | Erro de sintaxe | **Cria arquivo "10"!** |
| Regex `=~` | Suportado | Não suportado |
| Padrões `== *.sh` | Suportado | Não suportado |
| Lógicos `&&` `||` | Suportado | `-a` `-o` (obsoletos) |

### Por que `[ 5 < 10 ]` cria arquivo?
- `[ ]` é um comando normal (built-in `test`).
- `<` e `>` são operadores de **redirecionamento** do shell, processados ANTES do comando.
- `test 5 < 10` → redireciona stdin do arquivo "10" para o comando `test 5`.
- Como o arquivo "10" não existe, shell cria vazio. `test` vê só "5", que é string não-vazia = true (0).

### Conclusão
> **SEMPRE use `[[ ]]` em scripts Bash.** Só use `[ ]` se o shebang for `#!/bin/sh` (POSIX estrito).