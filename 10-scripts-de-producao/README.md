# 10-scripts-de-producao

## Objetivo
Escrever scripts que sobrevivem em produção: **seguros, idempotentes, depuráveis e auditáveis**. Este módulo ensina o "pulo do gato" entre scripts que funcionam no laptop e scripts que rodam às 3h da manhã sem supervisão.

## Analogia
> **Cozinha caseira vs. Cozinha industrial.** Em casa, se o bolo queima, você faz outro. Na indústria, o forno tem sensor de temperatura, timer redundante, alarme sonoro, sprinkler e log de cada batch. Scripts de produção *são* a cozinha industrial.

## Conceitos-chave

| Conceito | Por que importa | Exemplo no módulo |
|----------|-----------------|-------------------|
| `set -Eeuo pipefail` | Aborta em erro, variável não definida, falha no pipe | `modo-estrito.sh` |
| `trap` (EXIT, ERR, INT, TERM) | Limpeza garantida, logging de falha, sinal handling | `trap-limpeza.sh` |
| `flock` | Impede execução concorrente (race condition) | `lock-flock.sh` |
| `--dry-run` | Testa sem alterar estado | `dry-run.sh` |
| Logging estruturado | Auditoria, debugging, alerting | Todos exemplos |
| Códigos de saída padronizados | Automação confiável (systemd, cron, CI) | Template |

## Exemplos

| Script | Descrição | Conceitos demonstrados |
|--------|-----------|------------------------|
| [`modo-estrito.sh`](exemplos/modo-estrito.sh) | Compara comportamento com/sem `set -euo pipefail` + armadilhas do `set -e` | Modo estrito, subshell isolado, trap ERR |
| [`trap-limpeza.sh`](exemplos/trap-limpeza.sh) | Limpeza garantida (temp files, locks) em sucesso, erro, SIGINT, SIGTERM | `trap EXIT/ERR/INT/TERM`, `mktemp`, `flock` |
| [`lock-flock.sh`](exemplos/lock-flock.sh) | Lock não-bloqueante com FD dedicado, mensagem informativa | `flock -n`, FD 9, PID do holder |
| [`dry-run.sh`](exemplos/dry-run.sh) | Simulação de ações destrutivas com logging diferenciado | Flag `-n`, função `run()`, log levels |

## Exercícios

Veja [`exercicios/README.md`](exercicios/README.md) para 3 exercícios progressivos:

1. **Blindando script frágil** - Aplica todos conceitos em `backup-fragil.sh` → `backup-robusto.sh`
2. **Lock em backup existente** - Adiciona `flock` anti-concorrência em `backup-diario.sh`
3. **ShellCheck zero warnings** - Corrige 6+ avisos em `script-com-avisos.sh`

Gabarito em [`exercicios/gabarito/`](exercicios/gabarito/).

## Armadilhas Comuns

| Armadilha | Sintoma | Solução |
|-----------|---------|---------|
| `set -e` não dispara em `if`, `&&`, `||` | Erro silencioso em condicional | Use `set -E` + `trap ERR` (veja `modo-estrito.sh`) |
| Variável vazia expande para string vazia | `rm -rf "$DIR"/` apaga raiz | `set -u` + validação prévia |
| Pipe mascara erro do primeiro comando | `cmd1 \| cmd2` retorna 0 mesmo se `cmd1` falhar | `set -o pipefail` |
| `flock` em `/tmp` não sobrevive a reboot | Lock some após reboot | Use `/var/lock/` ou diretório persistente |
| Dry-run não testa efeitos colaterais | `--dry-run` passa mas execução real falha | Valide pré-condições *antes* do dry-run |

## Referências

- `man bash` → *The Set Builtin* / *Signals*
- `man flock`
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Template base: [`../templates/script-producao.sh`](../templates/script-producao.sh)

## Próximos Passos

Módulo 11: **Administração de Servidores** — Aplica este template em automação real (backup, saúde, frota).