# Módulo 02: Variáveis e Parâmetros

> **Analogia:** variáveis são **etiquetas** em caixas. `nome="servidor"` cola a etiqueta "servidor" na caixa. Parâmetros são caixas que chegam **prontas** de fora quando você chama o script.

## Objetivos

Ao final deste módulo você será capaz de:

- Criar, ler e apagar variáveis locais e de ambiente
- Usar expansão segura (`"$var"`, `${var:-default}`, `${var:=default}`)
- Receber argumentos posicionais (`$1`, `$2`...) e especiais (`$#`, `$@`, `$*`, `$?`)
- Trabalhar com arrays indexados e associativos
- Entender escopo: global vs `local` dentro de funções

---

## 1. Variáveis — o básico

```bash
# Atribuição (SEM espaços ao redor do =)
nome="servidor-web"
porta=443
ativo=true

# Leitura — SEMPRE com aspas duplas
echo "Servidor: $nome"           # funciona mas frágil
echo "Servidor: ${nome}"         # melhor (explícito)
echo "Porta: ${porta:-80}"       # default se vazio/não definido
echo "IP: ${ip:=127.0.0.1}"      # default E atribui na variável
```

| Sintaxe | Efeito |
|---------|--------|
| `var=valor` | Atribui (sem espaços!) |
| `"$var"` | Expansão segura (preserva espaços/quebras) |
| `${var:-x}` | Usa `x` se `var` vazio/não definido (não altera `var`) |
| `${var:=x}` | Usa `x` se vazio/não definido **E atribui** em `var` |
| `${var:+x}` | Usa `x` se `var` **tem** valor; vazio caso contrário |
| `${#var}` | Tamanho da string |
| `unset var` | Apaga a variável |

> **Armadilha:** `var = valor` (com espaços) executa o comando `var` com argumentos `=` e `valor`. **Sempre** `var=valor`.

✏️ **Teste agora:**
```bash
x="hello world"; echo "$x"        # preserva espaços
y=hello world; echo "$y"          # erro: comando "world" não existe
```

---

## 2. Variáveis de ambiente vs locais

```bash
export EDITOR=vim          # variável de ambiente (filhos herdam)
local_temp="/tmp/meu"      # variável local do shell atual
```

| Comando | Mostra |
|---------|--------|
| `env` ou `printenv` | Só variáveis exportadas |
| `set` | Todas (inclui funções, locais, não exportadas) |
| `declare -p VAR` | Declaração completa (tipo, escopo, valor) |

---

## 3. Parâmetros posicionais e especiais

```bash
# ./script.sh arg1 arg2 arg3
$1    # "arg1"
$2    # "arg2"
$#    # 3 (quantidade)
$@    # "arg1" "arg2" "arg3" (array preserva espaços) — USE ESTE
$*    # "arg1 arg2 arg3" (string única, IFS-dependent)
$?    # código de saída do último comando
$$    # PID do shell atual
$!    # PID do último background
```

> **Regra de ouro:** Use `"$@"` (com aspas) para iterar argumentos. Nunca `$*` sem aspas.

✏️ **Teste agora:**
```bash
cat > teste_args.sh << 'EOF'
#!/usr/bin/env bash
echo "Total: $#"
for arg in "$@"; do
    echo "Arg: [$arg]"
done
EOF
chmod +x teste_args.sh
./teste_args.sh "um" "dois tres" "quatro"
```

---

## 4. Arrays indexados

```bash
servidores=("web01" "web02" "db01")
servidores[3]="cache01"        # índice explícito
servidores+=("backup01")       # append

echo "${servidores[0]}"        # web01
echo "${servidores[@]}"        # todos elementos
echo "${#servidores[@]}"       # quantidade (4)
echo "${!servidores[@]}"       # índices (0 1 2 3)

# Iteração correta
for s in "${servidores[@]}"; do
    echo "Verificando $s..."
done
```

---

## 5. Arrays associativos (hash/dicionário) — requer Bash 4+

```bash
declare -A ports=( ["http"]=80 ["https"]=443 ["ssh"]=22 )
ports["dns"]=53

echo "${ports[https]}"         # 443
echo "${ports[@]}"             # valores
echo "${!ports[@]}"            # chaves
echo "${#ports[@]}"            # quantidade

for svc in "${!ports[@]}"; do
    echo "$svc -> ${ports[$svc]}"
done
```

---

## 6. Escopo em funções — `local` é obrigatório

```bash
contador=10

incrementa() {
    local contador=0           # variável LOCAL — não vaza
    contador=$((contador + 1))
    echo "Dentro: $contador"
}

incrementa
echo "Fora: $contador"         # ainda 10
```

> **Regra:** **Toda** variável dentro de função deve ser `local`, exceto se **intencionalmente** global.

---

## Armadilhas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| Variável some depois da função | Esqueceu `local` | `local var=valor` |
| Espaços quebram loop | Usou `$*` sem aspas | `for x in "$@"` |
| Default não funciona | Usou `${var:-x}` mas var existe vazia | `${var:-x}` funciona; `${var+x}` é diferente |
| Array associativo falha | Bash < 4 | `bash --version`; use `declare -A` |
| `readonly` impede reatribuição | Variável declarada `readonly` | Não use `readonly` em variáveis que mudam |

---

## Prática

### Exemplos conceituais (sem boilerplate)
- [`exemplos/conceito-variaveis.sh`](exemplos/conceito-variaveis.sh) — atribuição, expansão, defaults
- [`exemplos/conceito-arrays.sh`](exemplos/conceito-arrays.sh) — indexados e associativos
- [`exemplos/conceito-parametros.sh`](exemplos/conceito-parametros.sh) — `$@`, `$#`, shift

### Exemplos nível produção (com template completo)
- [`../07-menus-e-entrada/exemplos/integracao/producao-parse-args.sh`](../07-menus-e-entrada/exemplos/integracao/producao-parse-args.sh) — parsing robusto com validação (movido para M07)

### Exercícios
Veja [`exercicios/README.md`](exercicios/README.md) para 6 exercícios progressivos + autoavaliação.

---

## Autoavaliação

- [ ] Sei a diferença entre `$var`, `${var}`, `"$var"`, `${var:-x}`, `${var:=x}`
- [ ] Sei quando usar `export` vs variável local
- [ ] Sei iterar argumentos corretamente com `"$@"`
- [ ] Sei criar e iterar arrays indexados e associativos
- [ ] Sei por que `local` dentro de função é obrigatório
- [ ] Sei o que `$#`, `$?`, `$$`, `$!` retornam

Se marcou todos, siga para o [Módulo 03](../03-testes-e-operadores/).