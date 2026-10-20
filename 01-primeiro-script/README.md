# Módulo 01: Primeiro script

## Objetivos

Ao final deste módulo você será capaz de:

- Explicar o que é um shell script.
- Criar um arquivo de script com o *shebang* correto.
- Tornar o script executável e rodá-lo de três formas diferentes.
- Documentar com comentários.
- Exibir texto com `echo` e `printf`.
- Entender códigos de saída (`exit`).
- Colocar um script no `PATH` para usá-lo como qualquer comando.
- Depurar o básico com `bash -x`.

## 1. O que é um shell script

Um arquivo de texto com comandos que o shell executa **de cima para baixo, uma linha por vez**. Tudo o que você aprendeu no [módulo 00](../00-linux-essencial/) pode ser colocado em um script e repetido quantas vezes quiser.

> **Analogia:** o script é uma receita escrita. O shell é o cozinheiro que lê linha por linha e executa sem questionar. Se a receita disser "jogue sal", ele joga. Se disser "apague tudo", ele apaga. Por isso o cuidado com o que você escreve.

## 2. Anatomia do menor script possível

```bash
#!/usr/bin/env bash
# ola.sh - exibe uma saudação
echo "Olá, mundo!"
```

| Linha | Papel |
|---|---|
| `#!/usr/bin/env bash` | **Shebang**: diz ao sistema qual interpretador usar |
| `# ola.sh ...` | **Comentário**: o shell ignora; serve para humanos |
| `echo "Olá, mundo!"` | O comando que será executado |

### Sobre o shebang

- Deve ser a **primeira linha** do arquivo, sem espaço antes de `#!`.
- `#!/usr/bin/env bash` procura o `bash` no `PATH` (mais portável).
- `#!/bin/bash` aponta para um caminho fixo (também comum e válido).
- Sem shebang, o sistema usa o shell de quem chamou, o que pode se comportar diferente.

## 3. Criando e executando

### Passo 1: criar o arquivo

```bash
nano ola.sh        # ou vim, ou qualquer editor
```

Ou direto pelo terminal:

```bash
cat > ola.sh << 'EOF'
#!/usr/bin/env bash
echo "Olá, mundo!"
EOF
```

### Passo 2: dar permissão de execução

```bash
chmod +x ola.sh
ls -l ola.sh       # deve aparecer -rwxr-xr-x
```

### Passo 3: executar

Há três formas, com diferenças importantes:

| Forma | Comando | Precisa de `chmod +x`? | Usa o shebang? |
|---|---|---|---|
| Caminho explícito | `./ola.sh` | Sim | Sim |
| Chamando o interpretador | `bash ola.sh` | Não | Não (usa o `bash` informado) |
| `source` (ou `.`) | `source ola.sh` | Não | Não; roda **no shell atual** |

> **Por que `./`?** Por segurança, o Linux não procura executáveis no diretório atual. `./` diz "o arquivo está aqui".

A diferença do `source` só fica clara quando houver variáveis (módulo 02): o script executado normalmente roda em um "processo filho" e não altera o seu shell. O `source` roda dentro do seu shell.

## 4. Comentários

```bash
#!/usr/bin/env bash
# Comentário de linha inteira

echo "Backup iniciado"   # comentário no fim da linha
```

Boas práticas para um cabeçalho de script:

```bash
#!/usr/bin/env bash
#
# nome.sh - o que o script faz, em uma linha
#
# Autor:  seu nome
# Data:   2026-10-12
```

Comente o **porquê**, não o óbvio. `# soma 1` ao lado de uma soma não ajuda; `# o serviço demora 5s para subir` ajuda.

## 5. Exibindo texto: `echo` e `printf`

```bash
echo "Texto simples"
echo -n "Sem quebra de linha"      # -n suprime o \n final
echo -e "Linha 1\nLinha 2"         # -e interpreta \n e \t
```

`printf` é mais previsível e portável, e formata melhor:

```bash
printf "Servidor: %s\n" "web01"
printf "%-10s %s\n" "Nome" "Status"      # %-10s: texto alinhado à esquerda em 10 colunas
printf "%5.1f%%\n" 93.456                # número com 1 casa decimal e símbolo %
```

| Formato | Significado |
|---|---|
| `%s` | texto |
| `%d` | inteiro |
| `%f` | decimal |
| `\n` | nova linha |
| `\t` | tabulação |

> **Regra prática:** use `echo` para mensagens simples e `printf` quando precisar de formatação ou de comportamento previsível.

### Aspas simples e duplas (introdução)

```bash
echo "Texto com    espaços"     # aspas duplas preservam espaços
echo 'Texto literal'            # aspas simples: nada é interpretado
```

O comportamento delas com variáveis fica para o módulo 02.

## 6. Códigos de saída

Todo comando termina com um número: **0 significa sucesso, qualquer outro valor significa falha**. Você pode ver o código do último comando executado com `$?`.

```bash
ls /etc
echo $?            # 0: deu certo

ls /nao-existe
echo $?            # diferente de 0 (normalmente 2): falhou
```

Seu script também devolve um código, com `exit`:

```bash
#!/usr/bin/env bash
echo "Tudo certo"
exit 0             # sucesso
```

```bash
#!/usr/bin/env bash
echo "Algo deu errado" >&2     # mensagem de erro vai para stderr
exit 1                         # falha
```

Sem `exit`, o script devolve o código do **último comando executado**.

Por que isso importa em infraestrutura? Cron, systemd, pipelines de CI e ferramentas de monitoramento **decidem o que fazer a partir do código de saída**. Um script que sempre devolve 0, mesmo falhando, esconde problemas.

Convenção comum:

| Código | Uso típico |
|---|---|
| `0` | Sucesso |
| `1` | Erro genérico |
| `2` | Uso incorreto (argumentos errados) |
| `126` | Arquivo sem permissão de execução |
| `127` | Comando não encontrado |

## 7. Colocando o script no PATH

O `PATH` é a lista de diretórios onde o shell procura comandos.

```bash
echo "$PATH"
```

Para usar seu script de qualquer lugar, sem `./`:

```bash
mkdir -p ~/bin
cp ola.sh ~/bin/ola
chmod +x ~/bin/ola
# em muitas distros ~/bin já está no PATH após novo login; se não estiver:
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

ola       # agora funciona de qualquer diretório
```

Em servidores, scripts compartilhados costumam ficar em `/usr/local/bin`.

## 8. Depuração básica

Quando algo não funciona como esperado:

```bash
bash -x ola.sh        # mostra cada comando antes de executá-lo (precedido de +)
bash -n ola.sh        # só verifica a sintaxe, sem executar
```

Use também o **ShellCheck**, que aponta erros e más práticas:

```bash
shellcheck ola.sh
```

## Armadilhas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Permission denied` ao rodar `./script.sh` | Falta `chmod +x` | `chmod +x script.sh` |
| `bad interpreter: /usr/bin/env bash^M` | Arquivo salvo com fim de linha do Windows (CRLF) | `sed -i 's/\r$//' script.sh` ou configure o editor para LF |
| `command not found` ao rodar `script.sh` | Falta o `./` (diretório atual não está no PATH) | `./script.sh` |
| Shebang ignorado | Não está na linha 1, ou há espaço antes do `#` | Corrija a primeira linha |
| `No such file or directory` com shebang certo | Caminho do interpretador errado | `which bash` e ajuste |

> **Atenção para quem edita no Windows:** configure o editor (VS Code: canto inferior direito, "CRLF" → "LF") e mantenha o arquivo `.gitattributes` do projeto.

## Resumo

- Script = arquivo de texto com comandos, interpretado linha a linha.
- Primeira linha: `#!/usr/bin/env bash`.
- `chmod +x` e depois `./script.sh`.
- Comentários com `#`.
- `echo` para o simples, `printf` para formatado.
- Código de saída `0` = sucesso; `exit N` controla o do seu script.
- Depure com `bash -x` e valide com `shellcheck`.

## Prática

- Exemplos em [`exemplos/conceituais/`](exemplos/conceituais/):
  - `ola-mundo.sh` — script mínimo com shebang e echo
  - `saudacao.sh` — variável simples + echo + exit 0
  - `mostra-codigo.sh` — demonstra exit 0/1/2 e $?
  - `erro-stderr.sh` — stdout vs stderr (>&2) + exit 1
  - `multipla-forma.sh` — ./script vs bash script vs source script
- Exercícios em [`exercicios/`](exercicios/)
## Próximos passos além dos fundamentos

Ao concluir este módulo, você terá dominado os absolutamente básicos de shell script. Para continuar seu desenvolvimento como profissional de infraestrutura, recomendamos:

- [Referência sobre quando não usar shell](../referencia/quando-nao-usar-shell.md) - Diretrizes detalhadas para julgamento técnico na escolha de ferramentas de automação

Próximo: [módulo 02, variáveis e parâmetros](../02-variaveis-e-parametros/).