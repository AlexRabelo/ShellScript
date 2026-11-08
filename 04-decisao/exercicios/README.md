# Exercícios: Módulo 04 — Decisão (if, case)

Crie os scripts em `~/ex04/`. Consulte o [gabarito](gabarito/) só depois de tentar.

---

## Exercícios

### 1. Classificador de arquivo
**Arquivo:** `classifica-arquivo.sh`
- Receba `$1` (caminho)
- Use if/elif/else para classificar: arquivo regular, diretório, link, socket, pipe, bloco, caractere, não existe
- Imprima: "Tipo: arquivo regular" etc.

### 2. Menu de serviço com case
**Arquivo:** `menu-servico.sh`
- Receba `$1`: start, stop, restart, status, enable, disable
- Use case com alternância (`|`) para agrupar: start|enable = "Ativando", stop|disable = "Desativando"
- restart sozinho = "Reiniciando"
- status sozinho = "Verificando"
- Default: imprima uso e `exit 2`

### 3. Validador de IP simples (if + regex)
**Arquivo:** `valida-ip.sh`
- Receba `$1` (IP)
- Use `if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]` para validar formato
- Se válido, separe octetos com `IFS=. read -r o1 o2 o3 o4 <<< "$1"`
- Valide que cada octeto <= 255
- Imprima "IP válido: 192.168.1.1" ou "IP inválido"

### 4. Calculadora simples (case + aritmética)
**Arquivo:** `calculadora.sh`
- Receba 3 args: `./calculadora.sh 10 + 5`
- `$2` é operador: +, -, *, /, %, **
- Use case no `$2` e `(( ))` para calcular
- Dividir por zero: imprima erro e `exit 1`
- Imprima resultado: "10 + 5 = 15"

### 5. Armadilha do && || (debug)
**Arquivo:** `armadilha-and-or.sh`
- Crie função `falso()` que retorna 1
- Teste: `true && falso || echo "executou?"` — o que imprime?
- Teste: `if true; then falso; else echo "else"; fi` — o que imprime?
- Explique a diferença em comentário

---

## Autoavaliação

- [ ] Sei escrever if/elif/else com sintaxe correta (`then` na linha)
- [ ] Sei usar case com padrões, alternância (`|`), glob (`*`), default (`*`)
- [ ] Sei por que `A && B || C` não é if-then-else
- [ ] Sei usar regex com `=~` dentro de `if [[ ]]`
- [ ] Sei testar código de saída de comando direto no `if`

Se marcou todos, siga para o [Módulo 05](../../05-lacos/).