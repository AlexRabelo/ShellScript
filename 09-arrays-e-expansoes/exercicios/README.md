# Exercícios: Módulo 09 — Arrays e Expansões

Crie os scripts em `~/ex09/`. Consulte o [gabarito](gabarito/) só depois de tentar.

---

## Exercícios

### 1. Manipulação de paths com expansões
**Arquivo:** `path-expansao.sh`
- Receba `$1` (caminho completo: `/home/user/docs/arquivo.tar.gz`)
- Use expansões para extrair e imprimir:
  - Diretório (`/home/user/docs`)
  - Nome do arquivo (`arquivo.tar.gz`)
  - Nome base sem extensão (`arquivo`)
  - Extensão (`tar.gz`)
- Teste com: `/etc/nginx/nginx.conf`, `/var/log/app.log`, `./script.sh`

### 2. Sanitização de string com // e case
**Arquivo:** `sanitiza.sh`
- Receba `$1` (string suja: `"  Usuario@Exemplo.COM  "`)
- Remova espaços nas pontas (use expansão `##` e `%%` ou `//`)
- Converta para minúsculas
- Substitua `@` por `_at_`
- Imprima resultado limpo: `usuario_at_exemplo.com`

### 3. Array associativo — configuração por ambiente
**Arquivo:** `config-ambiente.sh`
- `declare -A config=( ["dev"]="debug:true,port:8080" ["prod"]="debug:false,port:443" )`
- Receba `$1` (ambiente: dev|prod|homolog)
- Se ambiente não existe no array: erro e `exit 2`
- Parse a string `debug:true,port:8080` em variáveis separadas
- Imprima: "Ambiente: dev, Debug: true, Porta: 8080"

### 4. Leitura de CSV em array com IFS
**Arquivo:** `le-csv.sh`
- Arquivo CSV: `nome,idade,cidade` (uma linha por registro)
- Use `IFS=, read -r -a` em loop `while` para ler cada linha
- Pule cabeçalho (primeira linha)
- Imprima: "Nome: X, Idade: Y, Cidade: Z"

### 5. Mapfile + processamento
**Arquivo:** `processa-linhas.sh`
- Use `mapfile -t` para ler `/etc/passwd` em array
- Processe cada linha: extraia usuário (campo 1), shell (campo 7)
- Conte quantos usam `/bin/bash`, `/bin/zsh`, `/bin/sh`, outros
- Imprima resumo ordenado por contagem

### 6. Filtro de array com índices
**Arquivo:** `filtra-array.sh`
- Array: `ips=("10.0.1.1" "10.0.2.2" "192.168.1.1" "10.0.3.3" "172.16.1.1")`
- Crie novo array `privados` só com IPs `10.x.x.x` (use glob `10.*` no `case` ou `[[ =~ ]]`)
- Imprima IPs privados um por linha
- Use `declare -p privados` para mostrar estrutura final

---

## Autoavaliação

- [ ] Sei extrair dirname/basename/extensão com `# ## % %%`
- [ ] Sei sanitizar string com `//`, `^^`, `,,`
- [ ] Sei criar/iterar array associativo e parsear valores compostos
- [ ] Sei ler CSV com `IFS=, read -r -a`
- [ ] Sei usar `mapfile -t` para arquivo → array
- [ ] Sei filtrar array criando novo array com índices

Se marcou todos, siga para o [Módulo 10](../10-scripts-de-producao/).