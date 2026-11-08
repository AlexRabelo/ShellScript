# Exercícios: Módulo 05

Crie os scripts em um diretório de testes (por exemplo `~/ex05`). Consulte o [gabarito](gabarito/) só depois de tentar.

## Exercícios

1. **Tabuada com for.** Crie `tabuada.sh` que receba um número como argumento e imprima a tabuada de 1 a 10:
   - Ex: `./tabuada.sh 7` → imprime 7x1=7 até 7x10=70
   - Valide argumento numérico

2. **Conta erros em log (while read).** Crie `conta-erros.sh` que receba um arquivo de log:
   - Leia linha a linha com `while IFS= read -r`
   - Conte quantas linhas contêm "ERROR" ou "ERRO" (case-insensitive)
   - Imprima o total no final
   - Use `grep -i` dentro do laço ou teste `[[ ${linha^^} == *ERROR* ]]`

3. **Retry de HTTP check.** Crie `retry-http.sh` que receba URL e tente até 5 vezes:
   - Use `curl -fsS -o /dev/null -w "%{http_code}" "$URL"` para testar
   - Considere sucesso apenas códigos 2xx
   - Entre tentativas, pause 2 segundos e imprima status
   - Se sucesso, imprima código HTTP e tempo total; se falhar todas, exit 1

4. **Processa CSV de servidores.** Crie `processa-servidores.sh` que leia um CSV:
   - Formato: NOME,IP,AMBIENTE,ROLE
   - Para cada linha, teste ping no IP (1 pacote, 1s timeout)
   - Classifique: ONLINE / OFFLINE
   - No final, imprima resumo por ambiente (ex: producao: 3/4 online)

5. **Limpeza segura com confirmação.** Crie `limpeza-segura.sh`:
   - Receba DIRETORIO, PADRAO (ex: *.tmp), DIAS
   - Liste arquivos que casam com padrão e têm mtime > DIAS
   - Mostre tamanho total a liberar
   - Peça confirmação `[s/N]` antes de apagar
   - Use `find -print0` e `while IFS= read -r -d ''` para nomes com espaços

6. **Monitor contínuo de processos.** Crie `monitora-processo.sh`:
   - Receba NOME_PROCESSO e INTERVALO (segundos)
   - Em loop infinito (`while true`), use `pgrep -c` para contar instâncias
   - Se count == 0, imprima ALERTA e toque beep (`echo -e '\a'`)
   - Se count > 0, imprima "OK: N instâncias"
   - Pause INTERVALO segundos entre verificações
   - Ctrl+C para sair graciosamente (trap INT)

7. **Deploy em múltiplos hosts (for + ssh).** Crie `deploy-hosts.sh`:
   - Receba ARQUIVO_HOSTS (um por linha) e COMANDO
   - Para cada host, execute COMANDO via SSH com `ssh -o BatchMode=yes -o ConnectTimeout=5`
   - Capture saída e código de saída
   - Mostre: HOST - SUCESSO/FALHA - SAÍDA
   - No final, resumo de quantos sucessos e falhas

8. **Until para aguardar lock.** Crie `aguarda-lock.sh`:
   - Receba CAMINHO_LOCKFILE
   - Use `until` para tentar adquirir lock com `flock -n`
   - Mostre "Aguardando lock..." a cada 2s
   - Quando conseguir, imprima "Lock obtido!" e mantenha o script rodando por 5s simulando trabalho
   - Solte o lock ao sair (trap EXIT)

9. **Break e Continue.** Crie `filtra-servidores.sh`:
   - Array interno com 10 servidores (mix de online/offline)
   - Loop `for` sobre todos
   - Se servidor estiver em manutenção (lista de exceção), use `continue` para pular
   - Se encontrar 3 offline consecutivos, use `break` para abortar tudo
   - Imprima decisões de continue/break

10. **Paralelismo simples com xargs.** Crie `ping-paralelo.sh`:
    - Receba arquivo com lista de IPs/hosts (um por linha)
    - Use `xargs -P 10 -I {} ping -c 1 -W 1 {}`
    - Capture saída e mostre apenas os que responderam
    - Compare tempo com versão sequencial

## Autoavaliação

- Sei usar `for` para listas, sequências e globs?
- Sei ler arquivos linha a linha com `while IFS= read -r`?
- Sei a diferença entre `while` e `until`?
- Sei implementar retry loop com limite de tentativas e backoff?
- Sei usar `break` e `continue` corretamente?
- Sei por que NÃO usar `for f in $(ls)`?
- Sei usar `find -print0` com `read -r -d ''` para arquivos com espaços?
- Sei fazer paralelismo simples com `xargs -P`?

Se respondeu "sim" a todas, siga para o [módulo 06](../../06-funcoes/).