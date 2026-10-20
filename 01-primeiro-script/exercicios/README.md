# Exercícios: Módulo 01

Crie os scripts em um diretório de testes (por exemplo `~/ex01`). Consulte o [gabarito](gabarito/) só depois de tentar.

## Exercícios

1. **Saudação.** Crie `saudacao.sh` que exiba duas linhas: `Bem-vindo ao curso de shell` e `Hoje é um bom dia para automatizar`. Torne-o executável e rode com `./saudacao.sh`.

2. **Três formas de executar.** Rode o script do exercício 1 com `./saudacao.sh`, com `bash saudacao.sh` e com `source saudacao.sh`. Anote o que mudou (nada deve mudar na saída ainda).

3. **Cabeçalho.** Acrescente ao `saudacao.sh` um cabeçalho de comentário com nome, descrição, uso e data.

4. **Tabela com printf.** Crie `tabela.sh` que exiba, alinhado em colunas:

   ```
   SERVIDOR   FUNCAO     STATUS
   web01      frontend   ativo
   db01       banco      ativo
   bkp01      backup     parado
   ```

5. **Relatório de disco.** Crie `relatorio-disco.sh` que mostre um título, o resultado de `df -h` e o tamanho de `/var/log` com `du -sh`. Esconda erros de permissão.

6. **Código de saída.** Crie `checa-arquivo.sh` que verifique se `/etc/passwd` existe usando o comando `ls /etc/passwd > /dev/null 2>&1`, exiba o código de saída (`$?`) e termine com esse mesmo código. *(Ainda não vimos `if`; use só `$?` e `exit`.)*

7. **Erro para stderr.** Crie `falha.sh` que escreva `ERRO: configuração ausente` no **stderr** e termine com código `2`. Prove que a mensagem vai para stderr rodando `./falha.sh > saida.txt` (a mensagem deve continuar aparecendo na tela e `saida.txt` deve ficar vazio).

8. **No PATH.** Copie `saudacao.sh` para `~/bin/saudacao` e execute apenas `saudacao` de outro diretório.

9. **Depuração.** Rode `bash -x relatorio-disco.sh` e identifique no resultado onde começa cada comando (linhas que iniciam com `+`).

10. **Caçando o erro.** O script abaixo falha. Descubra por quê, sem rodar com `bash -x` primeiro:

    ```bash
     #!/usr/bin/env bash
    echo "Iniciando"
    ech "Finalizando"
    ```

    *(São dois problemas.)*

## Autoavaliação

- Sei explicar o que o shebang faz?
- Sei por que `./script.sh` precisa do `./`?
- Sei a diferença entre `bash script.sh` e `source script.sh`?
- Sei por que o código de saída importa para o cron e o systemd?

Se respondeu "sim" a todas, siga para o [módulo 02](../../02-variaveis-e-parametros/).