# Módulo 00: Linux essencial

Antes de escrever scripts, é preciso dominar os comandos que eles vão executar. **Um shell script é, no fundo, uma lista de comandos que você digitaria no terminal, salvos em um arquivo.** Se você sabe usar o terminal, já sabe metade do shell script.

> **Analogia:** o terminal é a cozinha, os comandos são as facas e panelas. Um script é a receita que alguém escreveu para você não precisar lembrar de cada passo.

## Objetivos

Ao final deste módulo você será capaz de:

- Entender o que são terminal, shell e Bash.
- Navegar pelo sistema de arquivos.
- Criar, copiar, mover, apagar e ler arquivos.
- Interpretar e alterar permissões.
- Combinar comandos com pipes e redirecionamentos.
- Pedir ajuda ao próprio sistema (`man`, `--help`).

## 1. Terminal, shell e Bash

| Termo | O que é | Analogia |
|---|---|---|
| **Terminal** | A janela onde você digita | O balcão |
| **Shell** | O programa que interpreta o que você digita | O atendente |
| **Bash** | O shell mais comum em servidores Linux | Um atendente específico |

Descubra qual shell você está usando:

```bash
echo "$SHELL"      # shell padrão do usuário
bash --version     # versão do Bash instalada
```

## 2. Navegação

```bash
pwd                # onde estou? (print working directory)
ls                 # lista o conteúdo
ls -l              # lista detalhada (permissões, dono, tamanho, data)
ls -la             # inclui arquivos ocultos (começam com ponto)
ls -lh             # tamanhos legíveis (KB, MB)
cd /var/log        # entra em um diretório (caminho absoluto)
cd ..              # sobe um nível
cd ~               # vai para a home do usuário
cd -               # volta para o diretório anterior
```

**Caminho absoluto** começa em `/` (`/etc/ssh/sshd_config`). **Caminho relativo** parte de onde você está (`../logs/app.log`).

### Estrutura de diretórios que você vai usar sempre

| Diretório | Conteúdo |
|---|---|
| `/etc` | Arquivos de configuração |
| `/var/log` | Logs do sistema e das aplicações |
| `/home` | Diretórios dos usuários |
| `/tmp` | Arquivos temporários |
| `/usr/bin`, `/usr/local/bin` | Programas |
| `/opt` | Software de terceiros |
| `/proc`, `/sys` | Informações do kernel (virtual) |

## 3. Trabalhando com arquivos

```bash
mkdir projetos             # cria diretório
mkdir -p a/b/c             # cria toda a árvore, sem erro se já existir
touch arquivo.txt          # cria arquivo vazio (ou atualiza a data)
cp origem.txt destino.txt  # copia arquivo
cp -r pasta1 pasta2        # copia diretório inteiro
mv antigo.txt novo.txt     # renomeia ou move
rm arquivo.txt             # apaga arquivo
rm -r pasta                # apaga diretório e conteúdo
```

> **Cuidado:** `rm` **não tem lixeira**. Nunca rode `rm -rf` com variável ou caminho que você não conferiu. Em servidor, uma barra no lugar errado pode apagar o sistema.

### Lendo arquivos

```bash
cat arquivo.txt            # mostra tudo
head -n 5 arquivo.txt      # primeiras 5 linhas
tail -n 5 arquivo.txt      # últimas 5 linhas
tail -f /var/log/syslog    # acompanha o arquivo crescendo (Ctrl+C para sair)
less arquivo.txt           # navega página a página (q para sair)
wc -l arquivo.txt          # conta linhas
```

### Procurando

```bash
find /var/log -name "*.log"          # lista todos os arquivos de log em /var/log
find /tmp -type f -mtime +7          # arquivos temporários em /tmp com mais de 7 dias sem modificação (ótimo para limpeza)
grep "erro" arquivo.log              # filtra linhas exatas com "erro" em um arquivo de log
grep -i "erro" arquivo.log           # filtra linhas com "erro" ignorando maiúsculas/minúsculas (Erro, ERRO, erro)
grep -r "timeout" /etc               # procura recursivamente pelo termo "timeout" em todo o diretório /etc
```

## 4. Permissões

Rode `ls -l` e observe:

```
-rwxr-xr--  1  ana  devs  1024  out 12 10:00  deploy.sh
```

| Trecho | Significado |
|---|---|
| `-` | Tipo (`-` arquivo, `d` diretório, `l` link) |
| `rwx` | Permissões do **dono** (`ana`) |
| `r-x` | Permissões do **grupo** (`devs`) |
| `r--` | Permissões de **outros** |

`r` = ler (4), `w` = escrever (2), `x` = executar (1).

```bash
chmod +x script.sh         # dá permissão de execução
chmod 755 script.sh        # rwxr-xr-x
chmod 644 arquivo.txt      # rw-r--r--
chmod 600 chave.pem        # só o dono lê e escreve (obrigatório para chaves SSH)
chown ana:devs arquivo     # muda dono e grupo (requer root)
```

**Como ler o 755:** 7 = 4+2+1 (rwx) para o dono; 5 = 4+1 (r-x) para grupo; 5 para outros.

> **Analogia:** permissões são chaves de um prédio. O dono tem a chave mestra, o grupo tem a chave da sala comum, e os outros só entram no saguão.

### Executar como administrador

```bash
sudo comando               # executa um comando como root
whoami                     # qual usuário sou
id                         # usuário, UID e grupos
```

## 5. Pipes e redirecionamentos

É aqui que o shell mostra sua força: comandos pequenos que se combinam.

### Redirecionamento

| Operador | Efeito |
|---|---|
| `>` | Grava a saída em arquivo (**sobrescreve**) |
| `>>` | Acrescenta ao final do arquivo |
| `<` | Usa um arquivo como entrada |
| `2>` | Redireciona só as mensagens de **erro** |
| `2>&1` | Envia erros para o mesmo lugar da saída normal |
| `&>` | Envia saída e erros para o mesmo arquivo (Bash) |

```bash
ls -l > lista.txt              # grava (apaga o conteúdo anterior)
echo "mais uma linha" >> lista.txt
ls /pasta-inexistente 2> erros.txt
comando > tudo.log 2>&1        # saída e erro no mesmo arquivo
comando > /dev/null 2>&1       # descarta tudo (/dev/null é um "ralo")
```

Todo processo tem três canais: **stdin** (0, entrada), **stdout** (1, saída) e **stderr** (2, erros).

### Pipe `|`

O pipe liga a saída de um comando à entrada do próximo.

```bash
ls /etc | wc -l                         # quantos itens há em /etc?
cat /var/log/syslog | grep "ssh"        # filtra linhas com "ssh"
ps aux | grep nginx                     # processos do nginx
du -sh /var/* 2>/dev/null | sort -h     # diretórios por tamanho
```

> **Analogia:** o pipe é uma esteira de fábrica. Cada comando é uma estação que recebe a peça da anterior, faz uma transformação e passa adiante.

## 6. Ajuda do próprio sistema

```bash
man ls                  # manual completo (q para sair)
ls --help               # resumo das opções
type cd                 # o que é este comando? (interno, alias, programa)
which python3           # onde está o executável
history                 # comandos já digitados
```

Atalhos que economizam tempo: `Tab` completa nomes, `↑` repete comandos, `Ctrl+R` busca no histórico, `Ctrl+C` interrompe, `Ctrl+L` limpa a tela.

## 7. Comandos úteis para o dia a dia de infraestrutura

```bash
df -h                       # uso de disco por partição
du -sh /var/log             # tamanho de um diretório
free -h                     # memória
uptime                      # tempo ligado e carga média
ps aux                      # processos em execução
top                         # monitor interativo (digite q para sair)
ss -tulpn                   # portas em escuta
systemctl status ssh        # estado de um serviço
journalctl -u ssh -n 20     # últimos logs de um serviço
```

## Armadilhas comuns

| Problema | Causa | Solução |
|---|---|---|
| `Permission denied` | Falta permissão | `ls -l`, `chmod`, ou `sudo` se apropriado |
| `No such file or directory` | Caminho errado | `pwd` e `ls` para conferir |
| Arquivo ficou vazio | Usou `>` em vez de `>>` | `>>` acrescenta |
| Espaço no nome do arquivo | O shell separa por espaços | Use aspas: `cat "meu arquivo.txt"` |
| `rm -rf` apagou demais | Caminho ou variável errados | Confira com `ls` antes |

## Prática

- Rode o exemplo guiado: [`exemplos/laboratorio.sh`](exemplos/laboratorio.sh)
- Faça os exercícios: [`exercicios/`](exercicios/)

Quando estiver confortável, siga para o [módulo 01](../01-primeiro-script/).
