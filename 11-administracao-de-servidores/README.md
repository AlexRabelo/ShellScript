# 11-administracao-de-servidores

## Objetivo
Automatizar tarefas rotineiras de administração de servidores Linux: **relatórios de saúde, backup rotativo, execução em frota**. Aplicar o template de produção (Módulo 10) em cenários reais de infraestrutura.

## Analogia
> **Checklist de piloto vs. voo no automático.** O piloto verifica 200 itens antes de decolar. Seu script deve fazer o mesmo: checar disco, memória, serviços, rede — e só então executar a ação. Se algo estiver fora do padrão, aborta e alerta.

## Conceitos-chave

| Conceito | Aplicação prática |
|----------|-------------------|
| Coleta de métricas sistema | `/proc`, `/sys`, `df`, `free`, `uptime`, `systemctl` |
| Backup com retenção | Rotação por contagem/tempo, verificação de integridade (sha256) |
| Execução paralela em frota | SSH + `xargs -P` / `parallel`, timeout, coleta de resultados |
| Idempotência | Rodar 2x não quebra, não duplica, não corrompe |
| Segurança (least privilege) | Usuários dedicados, sudoers específico, chaves SSH restritas |

## Exemplos

| Script | Descrição | Conceitos demonstrados |
|--------|-----------|------------------------|
| [`relatorio-saude.sh`](exemplos/relatorio-saude.sh) | Relatório completo: CPU, RAM, disco, rede, serviços, logs, segurança | `/proc` parsing, `systemctl`, `ss`, `journalctl`, JSON output |
| [`backup-rotativo.sh`](exemplos/backup-rotativo.sh) | Backup tar + rotação por contagem + verificação sha256 + lock + dry-run | `flock`, `mktemp`, `sha256sum`, retenção, template produção |
| [`executa-em-hosts.sh`](exemplos/executa-em-hosts.sh) | Executa comando em lista de hosts via SSH com timeout, paralelo, JSON | `xargs -P`, `ssh -o ConnectTimeout`, `jq` para agregação |

## Exercícios

Veja [`exercicios/README.md`](exercicios/README.md) para 4 exercícios:

1. **Healthcheck de serviços** - `healthcheck-servicos.sh` (systemd + HTTP, JSON output)
2. **Backup remoto estendido** - `backup-rotativo-estendido.sh` (rsync/SSH, retenção dual, verificação remota)
3. **Inventário de frota** - `inventario-frota.sh` (usa `executa-em-hosts.sh` como lib, coleta padronizada)
4. **ShellCheck: limpeza de logs** - `limpa-logs-corrigido.sh` (corrige 8+ avisos)

Gabarito em [`exercicios/gabarito/`](exercicios/gabarito/).

## Armadilhas Comuns

| Armadilha | Sintoma | Solução |
|-----------|---------|---------|
| SSH sem timeout | Script trava indefinidamente se host cai | `ssh -o ConnectTimeout=10 -o BatchMode=yes` |
| `for host in $(cat hosts.txt)` | Falha com espaços/linhas vazias | `mapfile -t hosts < hosts.txt` ou `while IFS= read -r` |
| Backup sem verificação | Arquivo corrompido descoberto só no restore | `sha256sum` antes e depois, `--check` no restore |
| Retenção baseada só em nome | `backup-2026-10-13.tar.gz` falha se rodar 2x no dia | Use timestamp + hash ou counter no nome |
| Paralelismo sem limite | `xargs -P 100` derruba rede/CPU do bastion | `-P $(nproc)` ou valor fixo conservador (ex: 10) |

## Referências

- `man ssh` / `man ssh_config` → *ConnectTimeout, BatchMode, ControlMaster*
- `man rsync` → *--delete, --link-dest (backup incremental)*
- `man sha256sum`
- [OpenSSH Cookbook](https://en.wikibooks.org/wiki/OpenSSH/Cookbook)
- Template base: [`../templates/script-producao.sh`](../templates/script-producao.sh)

## Próximos Passos

Módulo 12: **Agendamento e Serviços** — Transforma esses scripts em systemd timers/services com sandbox, persistência, jitter.