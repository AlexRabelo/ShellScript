# Changelog

Todas as mudanças notáveis neste projeto ficam aqui.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/), e o projeto usa [Versionamento Semântico](https://semver.org/lang/pt-BR/).

---

## [1.0.0] — 2026-10-14

### Adicionado

- **Estrutura completa do curso**: 16 módulos progressivos (00 a 15), do Linux essencial ao SRE Toolkit
- **Headers profissionais padronizados** em todos os scripts — autor, licença, uso, códigos de saída, exemplos, dependências
- **Templates reutilizáveis**: `header-profissional.sh`, `alias.sh`, `script-producao.sh`
- **Modo estrito** (`set -Eeuo pipefail`) em todos os scripts de produção
- **Logging estruturado** com níveis (INFO, DEBUG, AVISO, ERRO, OK)
- **Suporte a dry-run** (`-n/--dry-run`) e verbose (`-v/--verbose`)
- **Tratamento de sinais** (EXIT, INT, TERM, ERR) com cleanup automático
- **Argument parsing robusto** com opções longas/curtas e validação
- **Funções utilitárias**: `requer_comando`, `run`, `die`, `usage` extraída do header
- **CI/CD com GitHub Actions**: ShellCheck, `bash -n`, BATS tests, validação de estrutura, conventional commits
- **Validação de estrutura** automática por módulo (README, exemplos, exercícios)

### Módulos Implementados

#### Parte 1: Fundamentos
- **Módulo 00** — Linux Essencial: navegação, arquivos, permissões, pipes, redirecionamentos
- **Módulo 01** — Primeiro Script: shebang, execução, variáveis básicas
- **Módulo 02** — Variáveis e Parâmetros: expansão, arrays, parâmetros posicionais, especiais
- **Módulo 03** — Testes e Operadores: `[ ]`, `[[ ]]`, operadores de string/numérico/arquivo

#### Parte 2: Controle de Fluxo
- **Módulo 04** — Decisão: if/elif/else, case, operadores lógicos
- **Módulo 05** — Laços: for, while, until, break/continue, IFS
- **Módulo 06** — Funções: escopo, variáveis locais, retorno, recursão
- **Módulo 07** — Menus e Entrada: select, read, getopts, menus interativos

#### Parte 3: Texto e Robustez
- **Módulo 08** — Processamento de Texto: grep, sed, awk, pipelines complexos
- **Módulo 09** — Arrays e Expansões: arrays associativos, manipulação de strings, parameter expansion
- **Módulo 10** — Scripts de Produção: idempotência, lockfiles, config files, validação rigorosa

#### Parte 4: Infraestrutura e SRE
- **Módulo 11** — Admin de Servidores: disco, usuários, processos, backup rotativo, systemd
- **Módulo 12** — Agendamento e Serviços: cron, systemd timers, unidades, logging
- **Módulo 13** — Observabilidade: healthchecks, análise de logs, alertas, métricas
- **Módulo 14** — AWS CLI, jq, Terraform: inventário, drift detection, automação cloud
- **Módulo 15** — Projeto Final (SRE Toolkit): CLI unificado com comandos backup/aws/drift/healthcheck/logs/terraform

### Corrigido

- **SC2148**: Shebang `#!/usr/bin/env bash` adicionado em `templates/alias.sh`
- **SC2316**: `export readonly` corrigido para declarações separadas em `templates/alias.sh`
- **SC2155**: Declare e assign de `SCRIPT_DIR` separados em `templates/header-profissional.sh`
- **Bug em aliases**: `&` trocado por `&&` em aliases de log tailing
- **README.md**: Status dos módulos corrigido — todos mostram "Completo" agora

### Documentação

- **melhorias.txt**: Análise crítica com seção "Quando não usar Shell" (ponto flutuante, estruturas complexas, performance, type safety)
- **COMPLETION_SUMMARY.md**: Resumo de conclusão do projeto
- **README.md**: Tabela de status, trilha de aprendizado, convenções, CI/CD
- **CHANGELOG.md**: Este arquivo

### Testes

- **BATS tests** no Módulo 15 (SRE Toolkit): log, validação, backup, drift, healthcheck
- **Testes de sintaxe** (`bash -n`) em todos os scripts
- **ShellCheck** zero warnings em todos os scripts

### Infraestrutura

- **systemd units** para timers de backup, healthcheck, log-analysis no Módulo 15
- **Diretório lib compartilhado** (`15-projeto-final/sre-toolkit/lib/`) com `log.sh`, `valida.sh`
- **Configuração de exemplo** (`sre-toolkit.conf.example`)

---

## [Unreleased]

### Planejado

- Adicionar testes BATS para módulos 01–14
- Implementar release automático via semantic-release
- Exemplos de integração com Prometheus/Grafana (Módulo 13)
- Documentar migração de scripts legados para o padrão profissional
- Módulo de troubleshooting/debugging avançado

---

**Nota**: Este changelog segue o padrão Keep a Changelog. Versões seguem SemVer.

- `Adicionado` — novas funcionalidades
- `Alterado` — mudanças em funcionalidades existentes
- `Depreciado` — funcionalidades que serão removidas
- `Removido` — funcionalidades removidas
- `Corrigido` — correções de bugs
- `Segurança` — vulnerabilidades corrigidas