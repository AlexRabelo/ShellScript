# Exercícios: Módulo 03 — Testes e Operadores

Crie os scripts em `~/ex03/`. Consulte o [gabarito](gabarito/) só depois de tentar.

---

## Exercícios

### 1. Testes de string
**Arquivo:** `teste-string.sh`
- Crie `nome=""` e `servico="nginx"`
- Teste se `nome` é vazia (`-z`) e imprima "nome vazio"
- Teste se `servico` NÃO é vazia (`-n`) e imprima "servico definido"
- Teste se `servico` contém "gin" (glob pattern)
- Teste se `servico` casa com regex `^ng.*x$`

### 2. Comparação numérica com (( ))
**Arquivo:** `teste-numerico.sh`
- `cpu=75`, `limite=80`
- Use `(( ))` para testar: cpu > limite, cpu >= limite, cpu < limite, cpu <= limite
- Imprima "ALERTA" se cpu > limite, "OK" caso contrário
- Incremente `cpu` com `(( cpu++ ))` e teste novamente

### 3. Testes de arquivo
**Arquivo:** `teste-arquivo.sh`
- Receba um caminho como `$1`
- Teste: existe? (`-e`), é arquivo? (`-f`), é diretório? (`-d`), é legível? (`-r`), tem conteúdo? (`-s`)
- Imprima resultado de cada teste
- Se não receber argumento, use `$0` (o próprio script) como default

### 4. Operadores lógicos combinados
**Arquivo:** `teste-logico.sh`
- `mem=85`, `cpu=60`, `disco=95`
- Imprima "CRÍTICO" se (mem > 90 OU disco > 90) E cpu > 50
- Imprima "ATENÇÃO" se mem > 80 OU disco > 80
- Imprima "OK" caso contrário
- Use parênteses para forçar precedência correta

### 5. Validador de entrada numérica
**Arquivo:** `valida-numero.sh`
- Receba `$1` (deve ser número inteiro positivo)
- Valide com regex `[[ $1 =~ ^[0-9]+$ ]]`
- Se inválido: imprima "Erro: '$1' não é número positivo" e `exit 2`
- Se válido: teste se > 100, > 1000, imprima faixa

### 6. Debug de condicional falhando
**Arquivo:** `debug-condicional.sh`
- Crie script que testa: `[[ "10" > "2" ]]` — lexicográfico!
- Corrija para comparação numérica correta
- Teste também: `[ 10 > 2 ]` — o que acontece? (redireciona!)
- Imprima explicação do erro

---

## Autoavaliação

- [ ] Sei usar `-z`, `-n`, `=`, `!=`, `==`, `=~`, glob em `[[ ]]`
- [ ] Sei comparar números com `(( ))` e operadores `-eq`/`-gt`
- [ ] Sei testar arquivo: `-e`, `-f`, `-d`, `-r`, `-w`, `-x`, `-s`, `-nt`, `-ot`
- [ ] Sei combinar com `&&`, `||`, `!` e parênteses em `[[ ]]`
- [ ] Sei por que `[ 10 > 2 ]` está errado e `[[ 10 > 2 ]]` é lexicográfico

Se marcou todos, siga para o [Módulo 04](../../04-decisao/).