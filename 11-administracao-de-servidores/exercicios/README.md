# Exercícios - Módulo 11: Administração de Servidores

## Pré-requisitos
- Módulo 10 completo (template de produção, `set -euo pipefail`, `trap`, `flock`, `dry-run`)
- Conhecer os exemplos: `relatorio-saude.sh`, `backup-rotativo.sh`, `executa-em-hosts.sh`
- `jq` instalado para JSON (`apt install jq`)

---

## Exercício 1: Healthcheck de Serviços Críticos

### Enunciado
Crie um script `healthcheck-servicos.sh` que verifica o status de uma lista de serviços systemd e endpoints HTTP, gerando relatório em texto ou JSON.

### Requisitos
- [ ] Lê lista de serviços de arquivo (um por linha: `nginx`, `postgresql`, `docker`)
- [ ] Lê lista de endpoints HTTP de arquivo (um por linha: `http://localhost:80/health`, `https://api.exemplo.com/status`)
- [ ] Opções: `-j/--json`, `-v/--verbose`, `-t/--timeout SEGUNDOS` (padrão: 5s)
- [ ] Verifica systemd: `systemctl is-active --quiet <serviço>`
- [ ] Verifica HTTP: `curl -sf --max-time <timeout> <url>` (código 2xx = OK)
- [ ] Saída texto: tabela colorida (verde=OK, vermelho=FALHA) ou simples
- [ ] Saída JSON: array de objetos com `tipo` (systemd/http), `nome`, `status` (ok/fail), `detalhes`, `timestamp`
- [ ] Código de saída: 0 se todos OK, 1 se qualquer falha, 2 uso incorreto
- [ ] Usa template de produção (modo estrito, trap, log, validações)
- [ ] Passa no `shellcheck`

### Arquivos de entrada esperados
```
# servicos.txt
nginx
postgresql
docker
sshd

# endpoints.txt
http://localhost:80/health
http://localhost:9090/metrics
https://api.exemplo.com/status
```

### Entregável
`healthcheck-servicos.sh` (executável)

---

## Exercício 2: Backup com Rotação e Verificação Remota

### Enunciado
Estenda o `backup-rotativo.sh` para suportar **backup remoto via SSH** (rsync over SSH) além do local.

### Requisitos
- [ ] Nova opção: `-R/--remoto USER@HOST:/caminho/destino`
- [ ] Se `-R` informado, usa `rsync -az --delete` em vez de `tar`
- [ ] Mantém retenção local E remota (aplica retenção nos dois lados)
- [ ] Verifica integridade remota: `ssh user@host "sha256sum -c arquivo.sha256"`
- [ ] Opção `--apenas-local` para forçar tar local mesmo com `-R`
- [ ] Dry-run mostra comandos rsync/ssh que seriam executados
- [ ] Lock file coordenado (nome inclui host remoto se aplicável)
- [ ] Passa no `shellcheck`

### Entregável
`backup-rotativo-estendido.sh` (baseado no exemplo, mantendo compatibilidade)

---

## Exercício 3: Inventário de Frota com Execução Paralela

### Enunciado
Crie um script `inventario-frota.sh` que usa `executa-em-hosts.sh` como biblioteca para coletar informações padronizadas de uma frota de servidores.

### Requisitos
- [ ] Fonte: arquivo de hosts (mesmo formato do `executa-em-hosts.sh`)
- [ ] Coleta por host (via SSH):
  - Hostname, uptime, kernel, distro (`/etc/os-release`)
  - CPU: modelo, núcleos, carga média
  - Memória: total, usada, %, swap
  - Disco: uso de `/` e `/var` (se existir)
  - Serviços ativos: `systemctl list-units --type=service --state=running --no-legend`
  - Pacotes instalados: `dpkg -l | wc -l` ou `rpm -qa | wc -l`
- [ ] Saída: JSON único com array de objetos (um por host)
- [ ] Opções: `-p/--paralelo N`, `-t/--timeout S`, `-o/--output ARQUIVO` (padrão: stdout)
- [ ] Trata hosts inacessíveis: inclui no JSON com `erro: "conexao_recusada"` ou similar
- [ ] Progress bar simples (pontos) se stdout for TTY e não JSON
- [ ] Passa no `shellcheck`

### Dica
Pode usar `source /caminho/executa-em-hosts.sh` e chamar funções internas, OU invocar o script via subshell e parsear saída. A abordagem com `source` é mais limpa mas exige cuidado com `set -e` e traps.

### Entregável
`inventario-frota.sh` + `executa-em-hosts.sh` (sem modificações, usado como lib)

---

## Exercício 4: Limpeza Segura de Logs Antigos (ShellCheck)

### Enunciado
O script abaixo tem **8+ avisos do ShellCheck**. Corrija todos sem mudar o comportamento.

```bash
#!/usr/bin/env bash
# limpa-logs-frágil.sh

DIR="/var/log/meu-app"
DIAS=30

arquivos=$(find $DIR -name "*.log" -mtime +$DIAS)
for arq in $arquivos; do
  tam=$(du -sh $arq | cut -f1)
  echo "Removendo $arq ($tam)"
  rm -f $arq
done

echo "Limpeza concluída"
```

### Avisos esperados (mínimo)
- SC2086: aspas em expansões (`$DIR`, `$DIAS`, `$arquivos`, `$arq`)
- SC2045: `for` em saída de `find` (usar `while read` ou `mapfile`)
- SC2002: `cat` desnecessário (não há cat aqui, mas `du -sh $arq` tem problema similar)
- SC2155: declaração e atribuição separadas
- SC2012: `find` com `-mtime` precisa de `-type f`
- SC2143: `grep` em saída de comando para verificar existência
- SC2034: variável não usada
- SC2120: função sem parâmetros (não há função, mas boa prática criar)

### Entregável
`limpa-logs-corrigido.sh` (zero avisos)

---

## Como Entregar

1. Crie os arquivos na pasta `gabarito/`
2. Teste cada um:
   ```bash
   shellcheck *.sh
   bash -n *.sh
   ./healthcheck-servicos.sh -h
   ./healthcheck-servicos.sh -f servicos.txt -e endpoints.txt
   ./backup-rotativo-estendido.sh -n -R user@host:/backup /dados /backup
   ./inventario-frota.sh -f hosts.txt -o inventario.json
   ./limpa-logs-corrigido.sh
   ```
3. Commite: `feat: exercícios módulo 11 - admin de servidores`

---

## Critérios de Avaliação

| Critério | Peso |
|----------|------|
| Template de produção aplicado corretamente | 25% |
| Funcionalidade completa (todos requisitos) | 30% |
| Tratamento de erros e edge cases | 15% |
| ShellCheck zero avisos | 10% |
| Código legível, documentado, auto-explicativo | 10% |
| Testes manuais demonstrados (prints/logs) | 10% |

---

## Dicas

> **Reutilize o template:** `cp ../templates/script-producao.sh meu-script.sh`

> **Teste falhas:** `systemctl stop nginx`, derrube rede, host inexistente, timeout.

> **JSON com jq:** `jq -n --arg k v '{key: $k}'` para construir objetos.

> **Arrays em Bash:** `declare -a arr=(); arr+=("item")` para construir listas.

> **Cores no terminal:** `VERDE='\033[0;32m'; VERMELHO='\033[0;31m'; NC='\033[0m'`