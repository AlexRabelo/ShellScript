# Curso de Shell Script (Bash) — Do Zero à Automação Real

[![Bash](https://img.shields.io/badge/Bash-4%2B-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-Clean-22D3EE)](https://www.shellcheck.net/)
[![Bats](https://img.shields.io/badge/Tests-Bats-3B82F6)](https://github.com/bats-core/bats-core)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Um curso prático e progressivo pra quem quer aprender shell script escrevendo código que aguenta produção. Começa no básico (navegar, arquivos, permissões) e vai até automação de servidores, observabilidade e AWS.

> **A analogia:** é como aprender a cozinhar. Primeiro você domina a faca e o fogão (comandos), depois segue receitas (scripts), e no final monta uma cozinha industrial que funciona sozinha às 3h da manhã (automação em produção).

---

## Como usar este repositório

| Se você quer... | Faça isso |
|----------------|-----------|
| **Aprender do zero** | Siga os módulos em ordem (00 → 15). Cada um pressupõe o anterior. |
| **Consultar algo rápido** | Vá direto ao módulo do assunto ou use a pasta [`referencia/`](referencia/) (cheat sheets e armadilhas comuns). |
| **Baixar material de consulta** | [Baixe o cheat-sheet completo](referencia/cheat-sheet.md) · [Cheat-sheets por módulo](referencia/) |
| **Começar um script novo** | Copie [`templates/script-producao.sh`](templates/script-producao.sh) e adapte — já vem com header, strict mode, logging, dry-run e trap de sinais. |

---

## O que você precisa antes de começar

- Uma máquina Linux (VM, WSL2 no Windows, EC2, container, servidor de laboratório — o que tiver à mão)
- Bash 4+ (`bash --version` pra confirmar)
- **Recomendado:** [ShellCheck](https://www.shellcheck.net/) (`apt install shellcheck` ou `brew install shellcheck`)
- **Módulo 14 (AWS):** AWS CLI v2 + `jq` + conta/sandbox AWS
- **Testes:** `bats` (`apt install bats`)

---

## Trilha de Aprendizado — O Que Você Vai Sair Sabendo Fazer

### Parte 1: Fundamentos (Módulos 00–03)
| Módulo | Tema | Ao final você vai conseguir... |
|--------|------|--------------------------------|
| [00](00-linux-essencial/) | Linux essencial | Navegar, manipular arquivos, entender permissões, usar pipes e redirecionamentos |
| [01](01-primeiro-script/) | Primeiro script | Criar, tornar executável e rodar um script |
| [02](02-variaveis-e-parametros/) | Variáveis e parâmetros | Guardar dados, receber argumentos, ler entrada do usuário |
| 03 *(em breve)* | Testes e operadores | Comparar strings, números e arquivos com `[ ]` e `[[ ]]` |

### Parte 2: Controle de Fluxo (Módulos 04–07 — *em breve*)
| Módulo | Tema | Ao final você vai conseguir... |
|--------|------|--------------------------------|
| 04 | Decisão | Usar `if`, `elif`, `else` e `case` com confiança |
| 05 | Laços | Repetir tarefas com `for`, `while`, `until`, controlar com `break`/`continue` |
| 06 | Funções | Organizar e reutilizar código, escopo de variáveis, retorno, recursão |
| 07 | Menus e entrada | Criar menus interativos (`select`), ler input (`read`), parsear flags (`getopts`) |

### Parte 3: Texto e Robustez (Módulos 08–10 — *em breve*)
| Módulo | Tema | Ao final você vai conseguir... |
|--------|------|--------------------------------|
| 08 | Processamento de texto | Filtrar e transformar logs/saídas com `grep`, `sed`, `awk`, pipelines complexos |
| 09 | Arrays e expansões | Trabalhar com listas, mapas (arrays associativos), manipulação nativa de strings |
| 10 | Scripts de produção | Escrever scripts seguros, idempotentes, depuráveis — lockfiles, config files, validação rigorosa |

### Parte 4: Infraestrutura e SRE (Módulos 11–15 — *em breve*)
| Módulo | Tema | Ao final você vai conseguir... |
|--------|------|--------------------------------|
| 11 | Admin de servidores | Automatizar disco, usuários, processos, backup rotativo, systemd |
| 12 | Agendamento e serviços | Usar `cron` e systemd timers, criar unidades, logging estruturado |
| 13 | Observabilidade | Criar healthchecks, analisar logs, enviar alertas, coletar métricas |
| 14 | AWS CLI, jq, Terraform | Automatizar nuvem com shell: inventário, drift detection, cost explorer |
| 15 | Projeto final | Construir um **SRE Toolkit** completo com CLI unificado |

---

## Estrutura Padrão de Cada Módulo

```
NN-nome-do-modulo/
├── README.md      # objetivos, teoria, analogia, sintaxe, armadilhas
├── exemplos/      # scripts comentados, executáveis, shellcheck clean
├── exercicios/    # enunciados (README.md) e gabarito/
└── test/          # testes automatizados (bats) — opcional mas recomendado
```

---

## Convenções Que Seguimos (E Por Quê)

| Convenção | Por que importa |
|-----------|-----------------|
| `#!/usr/bin/env bash` no topo | Portabilidade — funciona onde o bash estiver no PATH |
| Arquivos em `kebab-case`: `backup-diario.sh` | Arquivos com palavras em minúsculo separadas por hífen |
| `VARIAVEIS_DE_AMBIENTE` em MAIÚSCULAS, `variaveis_locais` em minúsculas | Distinção visual imediata de escopo |
| **Sempre** aspas em expansões: `"$variavel"` | Evita word splitting e globbing acidental |
| `shellcheck` limpo antes de commit | Pega bugs sutis que o olho humano deixa passar |
| Fins de linha **LF** (`.gitattributes`) | Evita pesadelos no Windows/WSL |
| **Headers padronizados** em todo script | Autor, licença, uso, códigos de saída, exemplos, dependências — tudo num lugar só |

---

## Qualidade e CI — O Que Roda Automático

Este repositório tem GitHub Actions que validam **todo push**:

- **ShellCheck** em todos `.sh` — zero warnings permitido
- **Bash syntax check** (`bash -n`) — pega erros de sintaxe antes de rodar
- **Bats tests** nos módulos que têm `test/`
- **Validação de estrutura** — cada módulo tem README, exemplos, exercícios

Veja o pipeline em [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml).

---

## Certificação e Roadmap

Este curso não emite certificado próprio. O seu certificado é o portfólio de scripts que você escreveu, testou e rodou aqui. O conteúdo, no entanto, cobre os tópicos de shell script exigidos pelas principais certificações de Linux do mercado:

| Certificação | O que cobre de shell script | Link |
|--------------|----------------------------|------|
| **LFCS** — Linux Foundation Certified System Administrator | Comandos básicos, variáveis, redirecionamento, pipes, testes condicionais, loops simples, criação e execução de scripts | [linuxfoundation.org](https://www.linuxfoundation.org/certification/lfcs) |
| **RHCSA** — Red Hat Certified System Administrator | Scripts de automação, `systemd` timers/services, SSH, agendamento com `cron`, gestão de usuários e permissões, resolução de problemas de boot | [redhat.com](https://www.redhat.com/en/services/training/rhcsa-red-hat-certified-system-administrator) |
| **CompTIA Linux+** | Fundamentos de linha de comando, shell scripting básico, automação de tarefas, segurança e permissões | [comptia.org](https://www.comptia.org/certifications/linux) |

### Roadmap sugerido

| Módulos | O que aprende | Próxima certificação |
|---------|---------------|----------------------|
| 00 → 05 | Comandos básicos, variáveis, testes, laços, decisões | LFCS (parte de comandos e scripts simples) |
| 06 → 10 | Funções, entrada de usuário, processamento de texto, scripts de produção com modo estrito e trap | RHCSA (parte de automação e script bash) |
| 11 → 15 | Administração de servidores, systemd timers, observabilidade, AWS, projeto final SRE Toolkit | RHCSA completo e perfil SRE / Linux Admin |

Não prometemos aprovação: prometemos que você terá escrito scripts reais que funcionam em produção — o que qualquer certificação exige na prática.

---

## Quer Contribuir?

1. **Branch por tema:** `release/v0.X-modulo-NN`
2. Rode `shellcheck` nos scripts novos e **execute-os** antes de commitar
3. **Ordem de complexidade:** não use no módulo N um conceito que só aparece no N+1
4. **Commits Conventional Commits:**
   - `feat(modulo-10): adiciona README e exemplos`
   - `test(modulo-15): adiciona bats para health check`
   - `docs(modulo-08): corrige armadilha no awk`
5. PR para `main` — merge só após CI verde (squash merge)

---

## Licença

[MIT License](LICENSE) — uso livre, inclusive comercial, com atribuição.

---

## Autor

**Alex Luiz Rabelo** — Especialista em Infraestrutura de TI, Middleware, DevOps & SRE
* GitHub: [github.com/AlexRabelo](https://github.com/AlexRabelo)
* Portfólio: [alexrabelo.github.io](https://alexrabelo.github.io/)
* LinkedIn: [linkedin.com/in/alexrabelo](https://www.linkedin.com/in/alexrabelo/)

---

*Este curso é mantido como portfolio técnico e material de estudo. Sugestões, críticas e correções são bem-vindas!*

---

*Transparência de IA: Este projeto foi estruturado e revisado com auxílio de ferramentas de IA e testado manualmente pelo autor.*
