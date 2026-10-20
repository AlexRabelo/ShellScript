# Exercícios - Módulo 10: Scripts de Produção

## Pré-requisitos
- Conhecer o template: [`../templates/script-producao.sh`](../templates/script-producao.sh)
- Estudar os exemplos: `modo-estrito.sh`, `trap-limpeza.sh`, `lock-flock.sh`, `dry-run.sh`
- Ter `shellcheck` instalado (`apt install shellcheck`)

---

## Exercício 1: Blindando um Script Frágil

### Enunciado
O script abaixo **funciona no seu laptop** mas **vai causar incidente em produção**. Sua tarefa: reescreva-o aplicando **todos** os conceitos do módulo 10.

```bash
#!/usr/bin/env bash
# backup-fragil.sh - BACKUP FRÁGIL (NÃO USE EM PRODUÇÃO)

DIR_ORIGEM=$1
DIR_DESTINO=$2

tar -czf $DIR_DESTINO/backup-$(date +%F).tar.gz $DIR_ORIGEM
echo "Backup concluído em $DIR_DESTINO/backup-$(date +%F).tar.gz"
```

### Problemas Identificados (mínimo 8)
1. Sem `set -euo pipefail`
2. Variáveis sem aspas (`$DIR_ORIGEM`, `$DIR_DESTINO`)
3. Sem validação de argumentos (quantidade, existência, permissões)
4. Sem verificação se `tar` existe
5. Sem `--dry-run`
6. Sem logging estruturado
7. Sem limpeza em caso de falha (`trap`)
8. Sem lock (duas execuções simultâneas corrompem backup)
9. Código de saída sempre 0 (mesmo se `tar` falhar)
10. Nome do arquivo com data avaliado duas vezes (pode virar meia-noite entre chamadas)

### Requisitos da Solução
- [ ] Modo estrito (`set -Eeuo pipefail`)
- [ ] Validação de 2 argumentos obrigatórios
- [ ] Verificação de pré-requisitos (`tar`, `date`, diretórios)
- [ ] Opção `-n/--dry-run` e `-v/--verbose`
- [ ] Logging com timestamp, nível, PID
- [ ] `trap` para limpeza (EXIT, ERR, INT, TERM)
- [ ] `flock` para impedir execução concorrente
- [ ] Arquivo temporário com `mktemp` + limpeza garantida
- [ ] Códigos de saída: 0=sucesso, 1=erro genérico, 2=uso incorreto, 3=pré-requisito
- [ ] Passa no `shellcheck` sem avisos
- [ ] Idempotente: rodar 2x seguidas não quebra nada

### Entregável
Arquivo: `backup-robusto.sh` (executável, com shebang, comentário de uso)

---

## Exercício 2: Lock em Script de Backup Existente

### Enunciado
Você herdou o script `backup-diario.sh` (abaixo). Ele roda via `cron` todo dia às 02:00. **O problema**: se o backup do dia anterior demorar mais de 24h (arquivos grandes, rede lenta), **dois backups rodam simultâneos** e corrompem o destino.

```bash
#!/usr/bin/env bash
# backup-diario.sh - Backup diário simples

set -euo pipefail

ORIGEM="/dados"
DESTINO="/backup/diario"
ARQUIVO="backup-$(date +%F).tar.gz"

mkdir -p "$DESTINO"
tar -czf "$DESTINO/$ARQUIVO" "$ORIGEM"
echo "OK: $DESTINO/$ARQUIVO"
```

### Tarefa
Adicione **lock com `flock`** para garantir que **nunca** haja duas execuções simultâneas.

### Requisitos
- [ ] Lock não bloqueante (`flock -n`) - segunda instância sai com código 1 e mensagem clara
- [ ] Lock file em local persistente (não `/tmp` - sobrevive a reboot)
- [ ] FD dedicado para o lock (não vazar FD)
- [ ] Mensagem de log informando PID da instância ativa se falhar
- [ ] Mantém `set -euo pipefail` e boas práticas existentes
- [ ] Passa no `shellcheck`

### Entregável
Arquivo: `backup-diario-com-lock.sh`

---

## Exercício 3: Caça aos Avisos do ShellCheck

### Enunciado
O script abaixo passa na execução mas **o ShellCheck reclama de 6+ problemas**. Corrija **todos** sem mudar o comportamento funcional.

```bash
#!/usr/bin/env bash
# script-com-avisos.sh

arquivos=$(ls /var/log/*.log)
for arq in $arquivos; do
  linhas=$(cat $arq | wc -l)
  echo "Arquivo: $arq, Linhas: $linhas"
done

if [ $linhas -gt 1000 ]; then
  echo "Arquivo grande detectado"
fi

funcao() {
  local var=$1
  echo $var
}

funcao "teste"
```

### Dicas
- Rode: `shellcheck script-com-avisos.sh`
- Cada aviso tem um código (SCxxxx) - pesquise no [ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki)
- Não suprima avisos com `# shellcheck disable=` a menos que **muito justificado**

### Entregável
Arquivo: `script-corrigido.sh` (zero avisos no ShellCheck)

---

## Como Entregar

1. Crie os 3 arquivos na pasta `gabarito/` (ou envie para revisão)
2. Teste cada um:
   ```bash
   shellcheck *.sh
   bash -n *.sh
   ./backup-robusto.sh -h
   ./backup-robusto.sh -n /etc /tmp/teste-backup
   ./backup-diario-com-lock.sh
   ./script-corrigido.sh
   ```
3. Commite com mensagem: `feat: exercícios módulo 10 - scripts de produção`

---

## Critérios de Avaliação

| Critério | Peso |
|----------|------|
| Modo estrito correto | 20% |
| Trap + limpeza garantida | 20% |
| Lock anti-concorrência | 15% |
| Dry-run funcional | 10% |
| Logging estruturado | 10% |
| Validações robustas | 10% |
| ShellCheck zero avisos | 10% |
| Código legível e comentado | 5% |

---

## Dicas de Ouro

> **Templates são seus amigos:** copie `../templates/script-producao.sh` e adapte.

> **Teste falhas:** `kill -TERM $PID`, `kill -INT $PID`, rode dois terminais ao mesmo tempo.

> **Leia o próprio código como se fosse de outra pessoa:** "o que acontece se `$DIR_DESTINO` não existir?"

> **`shellcheck` não é opcional:** é parte do CI/CD.

---

## Referências Rápidas

- `man flock` / `help flock`
- `man bash` → *Signals* / *Trap*
- `shellcheck -s bash script.sh`
- Exemplos do módulo: `../exemplos/`
- Template: `../templates/script-producao.sh`