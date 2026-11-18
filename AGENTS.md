# AGENTS.md — instruções para agentes neste repositório

Este repositório é um curso de Bash em português (módulos 00 → 15; publicados: 00, 01, 02, 09). Não há build system, `package.json`, compilação nem dev server. Executável = script `.sh` rodado com `bash` ou diretamente com `./`.

## Antes de começar

- `./scripts/setup-dev.sh` instala shellcheck, bats, jq, curl, pre-commit e commitizen (apt ou Homebrew).
- Confirme `bash --version` (Bash 4+ exigido).
- Módulo 14 (AWS): AWS CLI v2 + `jq` + conta/sandbox AWS — **credenciais reais nunca no repo**.
- Não existe `opencode.json`; instruções locais estão neste `AGENTS.md` e em `CLAUDE.md`.

## Comandos de qualidade (roda tudo antes de commitar)

| O que | Comando |
|-------|---------|
| ShellCheck (zero avisos) | `shellcheck --enable=all -x --severity=warning scripts templates` (CI ignora SC2001, SC2002, SC2015, SC2016, SC2034, SC2046, SC2086, SC2095, SC2116, SC2155, SC2178, SC2221, SC2222, SC2317) |
| Sintaxe Bash | `bash -n` em todos os `.sh` |
| Teste bats (um arquivo) | `bats test/arquivo.bats` — testes vivem em `NN-modulo/test/` |
| Headers obrigatórios | `./scripts/check-headers.sh` |
| Boas práticas shell | `./scripts/check-best-practices.sh` |
| Pre-commit local | `pre-commit install` — roda em cada commit; `commit-msg` valida Conventional Commits |

## Estrutura e convenções (aplicadas por CI e pré-commit)

- Módulo: `NN-nome-do-modulo/{README.md,exemplos/,exercicios/,test/}`
- Novo script: copie `templates/script-producao.sh` (header padronizado, `set -Eeuo pipefail`, logging, dry-run, trap de sinais)
- Shebang: `#!/usr/bin/env bash` | Strict mode nas primeiras 20 linhas: `set -Eeuo pipefail`
- Arquivos em `kebab-case` (ex.: `backup-diario.sh`)
- `VARIAVEIS_DE_AMBIENTE` maiúsculas, variáveis locais minúsculas, sempre `"$variavel"` com aspas
- Fins de linha **LF** (`.gitattributes` / `.editorconfig`; CRLF quebra scripts no Windows/WSL)
- Header do script deve conter: Autor, Versão, Descrição, Uso, Códigos de saída
- Não use no módulo N um conceito que só aparece no módulo N+1

## Git / PR / commits — regra de módulos

- **Não fazer pull de todos os módulos do GitHub.** Cada módulo deve ser desenvolvido em sua **branch individual** (`release/v0.X-modulo-NN`).
- O merge de uma branch de módulo para `main` só ocorre **com minha autorização** (squash merge, somente após CI verde).
- Conventional Commits: `feat(modulo-10): ...`, `test(modulo-15): ...`, `docs(modulo-08): ...`
- Rode `shellcheck` e execute os scripts antes de commitar

## Segurança

- Nunca versionar: `.env`, `*.pem`, `*.key`, `credentials`, `*.log`, `*.out`
- Módulo 14 (AWS): apenas conta/sandbox, credenciais nunca no repositório

## Design (referência para agentes)

- **README:** manter Markdown default do GitHub. Não reescrever em HTML/CSS — o GitHub renderiza Markdown nativamente e sanitiza HTML inline.
- **Design system unificado:** `docs/design-system/unified.css` é o source of truth (Primitive → Semantic → Component). Os arquivos antigos `docs/design-tokens.css` e `docs/design-telemetry.css` estão mantidos como referência histórica, mas novos componentes devem usar o `unified.css`.
- **Não criar novos CSS paralelos** sem atualizar o `unified.css` e o `docs/design-system/MASTER.md`.
- **Tipografia para conteúdo técnico:** `JetBrains Mono` para código/comandos (mono único, pesos 400/500, line-height 1.2) e `Source Sans 3` ou `Work Sans` para corpo, com fallback `system-ui`.
- **Contraste:** texto normal deve ter ≥4.5:1 contra o fundo em modo escuro (WCAG AA). Verificar com ferramenta de contraste antes de definir cores primárias.
- **Ícones:** não usar emoji como ícone estrutural. Usar SVG consistente (Heroicons/Lucide) se houver interface.
- **Checklist pré-entrega (UI):** contraste ≥4.5:1, focus visível para teclado, `prefers-reduced-motion` respeitado, responsivo em 375/768/1024/1440px, hover/transition 150–300ms.

## GitNexus — regras permanentes (preservadas)

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **ShellScript** (414 symbols, 421 relationships, 0 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact before editing.** Use `impact({target: "symbolName", direction: "upstream"})` or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .`; report callers, processes, and risk. Never substitute grep for graph analysis.
- **MUST analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "main"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "main" --repo .`.
- MUST warn on HIGH/CRITICAL `risk` pre-edit; never use `riskSharedAxes` to waive a HIGH/CRITICAL `risk` warning. Compare File/symbol: MCP File omits axes; Graph-RAG expands File.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- **MUST use `query({search_query: "concept"})` for concepts/flows, `context({name: "symbolName"})` for a named symbol, or `impact` for blast radius, on read-only callers, dependencies, imports, or execution flow.** Graph first; text search only for empty/`UNKNOWN`/literals.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/ShellScript/context` | Codebase overview, check index freshness |
| `gitnexus://repo/ShellScript/clusters` | All functional areas |
| `gitnexus://repo/ShellScript/processes` | All execution flows |
| `gitnexus://repo/ShellScript/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
