# Exercícios: Módulo 00

Faça no terminal, dentro de um diretório de testes (por exemplo `/tmp/ex00`). Só consulte o [gabarito](gabarito/respostas.md) depois de tentar.

## Preparação

```bash
mkdir -p /tmp/ex00 && cd /tmp/ex00
```

## Exercícios

1. Mostre em qual diretório você está e liste todos os arquivos dele, inclusive os ocultos, em formato detalhado.
2. Crie a estrutura `projeto/src` e `projeto/docs` com **um único** comando.
3. Crie o arquivo `projeto/docs/leia-me.txt` contendo a frase `Meu primeiro projeto`.
4. Acrescente uma segunda linha `Versao 1.0` ao mesmo arquivo, sem apagar a primeira.
5. Copie `leia-me.txt` para `projeto/src/` com o nome `copia.txt`.
6. Mostre apenas a **última linha** de `projeto/docs/leia-me.txt`.
7. Crie um arquivo `limpeza.sh` vazio e deixe-o executável apenas para o dono (os outros só leem).
8. Liste o conteúdo de `/etc` e conte quantos itens existem usando um pipe.
9. Rode `ls /nao-existe` mandando a mensagem de erro para `erro.log`, sem mostrá-la na tela.
10. Encontre todos os arquivos `.txt` dentro de `/tmp/ex00`.
11. Mostre os 5 maiores diretórios dentro de `/var` (dica: `du`, `sort`, `head`; esconda erros de permissão).
12. **Desafio:** conte quantas linhas do arquivo `/etc/passwd` contêm a palavra `nologin`.

## Autoavaliação

- Sei a diferença entre `>` e `>>`?
- Sei ler `-rwxr-x---` e dizer quem pode o quê?
- Sei explicar para que serve `2>&1`?

Se respondeu "sim" às três, siga para o [módulo 01](../../01-primeiro-script/).
