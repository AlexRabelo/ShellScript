# Gabarito: Módulo 00

Há mais de uma forma correta para vários itens. O importante é entender o porquê.

1. ```bash
   pwd
   ls -la
   ```

2. ```bash
   mkdir -p projeto/src projeto/docs
   ```
   `-p` cria os níveis necessários e não reclama se já existirem.

3. ```bash
   echo "Meu primeiro projeto" > projeto/docs/leia-me.txt
   ```

4. ```bash
   echo "Versao 1.0" >> projeto/docs/leia-me.txt
   ```
   Com `>` a primeira linha seria perdida.

5. ```bash
   cp projeto/docs/leia-me.txt projeto/src/copia.txt
   ```

6. ```bash
   tail -n 1 projeto/docs/leia-me.txt
   ```

7. ```bash
   touch limpeza.sh
   chmod 744 limpeza.sh      # dono: rwx; grupo e outros: r--
   ls -l limpeza.sh
   ```

8. ```bash
   ls /etc | wc -l
   ```

9. ```bash
   ls /nao-existe 2> erro.log
   ```

10. ```bash
    find /tmp/ex00 -name "*.txt"
    ```

11. ```bash
    du -s /var/* 2>/dev/null | sort -n -r | head -n 5
    ```
    `sort -n -r` ordena numericamente do maior para o menor; `2>/dev/null` descarta erros de permissão.

12. ```bash
    grep -c "nologin" /etc/passwd
    # ou, com pipe:
    grep "nologin" /etc/passwd | wc -l
    ```
