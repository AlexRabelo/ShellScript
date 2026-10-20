# Gabarito: Módulo 01

Os scripts completos dos exercícios 1, 4, 5, 6 e 7 estão nesta pasta. Abaixo, as explicações.

## 1 a 3: saudação

Ver [`saudacao.sh`](saudacao.sh). Passos:

```bash
chmod +x saudacao.sh
./saudacao.sh
bash saudacao.sh
source saudacao.sh
```

A saída é a mesma nas três formas. A diferença é **onde** o script roda: `./` e `bash` criam um processo filho; `source` executa no shell atual. Com variáveis (módulo 02) a diferença aparece.

## 4: tabela

Ver [`tabela.sh`](tabela.sh). `%-10s` reserva 10 colunas e alinha à esquerda.

## 5: relatório de disco

Ver [`relatorio-disco.sh`](relatorio-disco.sh). O `2> /dev/null` descarta os "Permission denied" do `du`.

## 6: código de saída

Ver [`checa-arquivo.sh`](checa-arquivo.sh). Ponto-chave: **qualquer comando altera o `$?`**, inclusive o `echo` que o exibe. Por isso o teste foi repetido antes do `exit`. No módulo 02 você aprenderá a guardar o valor em uma variável, que é a solução correta.

## 7: erro para stderr

Ver [`falha.sh`](falha.sh). Teste:

```bash
./falha.sh > saida.txt     # mensagem continua na tela
cat saida.txt              # vazio
./falha.sh 2> erros.txt    # agora a mensagem vai para o arquivo
echo $?                    # 0, pois é o código do último comando (o redirecionamento não muda isso)
```

Para ver o código do script, rode `./falha.sh; echo $?` (resultado `2`).

## 8: no PATH

```bash
mkdir -p ~/bin
cp saudacao.sh ~/bin/saudacao
chmod +x ~/bin/saudacao
cd /tmp
saudacao
```

Se o shell responder `command not found`, o `~/bin` não está no `PATH`: veja a seção 7 do README do módulo.

## 9: depuração

Na saída de `bash -x`, cada linha começando com `+` é um comando prestes a ser executado. As demais linhas são a saída dele.

## 10: caçando o erro

1. **Espaço antes do shebang** (` #!/usr/bin/env bash`): com espaço, a linha vira um comentário comum e o shebang é ignorado. Deve começar exatamente em `#!`.
2. **`ech` em vez de `echo`**: erro de digitação, gera `command not found` (código 127).

`bash -n` não pega o segundo erro (a sintaxe está válida, o comando é que não existe); o `shellcheck` avisa dos dois.
