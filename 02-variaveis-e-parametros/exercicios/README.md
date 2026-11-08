# Exercícios: Módulo 02 — Variáveis e Parâmetros

Crie os scripts em `~/ex02/`. Consulte o [gabarito](gabarito/) só depois de tentar.

---

## Exercícios

### 1. Variáveis e expansão básica
**Arquivo:** `expansao.sh`
- Crie variáveis: `app="nginx"`, `porta=80`, `versao=""`
- Imprima: "App: nginx, Porta: 80, Versão: 1.24 (default)"
- Use `${versao:-1.24}` para o default
- **Não altere** a variável `versao` (deve continuar vazia depois)

### 2. Default com atribuição (:=)
**Arquivo:** `default-atribuicao.sh`
- Crie `dir=""`
- Use `${dir:=/tmp/meuapp}` e imprima o resultado
- Verifique se `dir` agora vale `/tmp/meuapp`
- Crie o diretório se não existir: `mkdir -p "$dir"`

### 3. Arrays indexados
**Arquivo:** `array-indexado.sh`
- Crie array `hosts=("web01" "web02" "db01")`
- Adicione "cache01" no final
- Imprima: quantidade, índices, todos elementos
- Itere e imprima "Verificando: $host" para cada

### 4. Array associativo (ambientes → IPs)
**Arquivo:** `array-associativo.sh`
- `declare -A ips=( ["producao"]="10.0.1.10" ["homolog"]="10.0.2.20" )`
- Adicione `dev=10.0.3.30`
- Itere chaves e imprima: "Ambiente: producao → IP: 10.0.1.10"
- Imprima só o IP de homolog

### 5. Parâmetros posicionais — validador de args
**Arquivo:** `valida-args.sh`
- Receba exatamente 3 argumentos: `./valida-args.sh ARQUIVO DIRETORIO EXTENSAO`
- Se `$# -ne 3`: imprima uso e `exit 2`
- Valide que `$1` existe e é arquivo (`-f`)
- Valide que `$2` existe e é diretório (`-d`)
- Imprima: "OK: arquivo=$1, dir=$2, ext=$3"

### 6. Scope com `local` em função
**Arquivo:** `scope-local.sh`
- Variável global: `contador=100`
- Função `incrementa()` que:
  - Cria `local contador=0`
  - Incrementa 3 vezes em loop
  - Imprime valor final local
- Chame a função
- Imprima `contador` global (deve ser 100)

---

## Autoavaliação

- [ ] Sei a diferença entre `${var:-x}` (não altera) e `${var:=x}` (altera)
- [ ] Sei criar array indexado e associativo e iterar ambos corretamente
- [ ] Sei validar `$#` e testar arquivos/diretórios com `-f`/`-d`
- [ ] Sei por que `local` dentro de função evita vazamento de variável
- [ ] Sei iterar argumentos com `"$@"` (com aspas)

Se marcou todos, siga para o [Módulo 03](../../03-testes-e-operadores/).