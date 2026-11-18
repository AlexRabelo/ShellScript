# Design System MASTER — Curso Shell Script (Proposta)

> Este arquivo é uma **proposta** baseada na avaliação `ui-ux-pro-max` e nos tokens existentes em `docs/design-tokens.css` e `docs/design-telemetry.css`. Não altera nenhum arquivo existente. Requer autorização do autor antes de ser aplicado.

## 1. Escopo

- Produto: curso técnico de Bash/Shell Script em português
- Plataforma principal: README do GitHub (Markdown renderizado nativamente)
- Plataforma secundária (opcional): landing page em HTML via GitHub Pages
- Público: estudantes e profissionais de infraestrutura, DevOps, SRE
- Contexto de uso: leitura de documentação técnica, consulta de comandos, navegação por módulos

## 2. Decisão de interface: README

**Manter Markdown default do GitHub.** Motivos:

- Renderização nativa em web, mobile e CLI do GitHub
- Sem sanitização agressiva (diferente de HTML inline no README)
- Diff limpo e manutenção simples para conteúdo de código e tabelas
- Acessibilidade garantida pelo GitHub

**HTML customizado somente em landing page separada** (ex.: `landing/` ou `site/`), linkada do README, se o autor quiser identidade visual própria.

## 3. Paleta de cores (unificação proposta)

Os dois CSS existentes usam paletas ligeiramente diferentes. Proposta de unificação:

| Função | Hex | Uso |
|--------|-----|-----|
| Fundo principal (dark) | `#08090c` ou `#070b14` | Página / corpo |
| Superfície / card | `#0f172a` ou `#1e293b` | Cards, seções elevadas |
| Texto primário | `#f1f5f9` ou `#f8fafc` | Títulos, texto principal |
| Texto secundário | `#94a3b8` | Legendas, metadados |
| Texto muted | `#64748b` | Texto secundário de menor ênfase |
| Primary (Ciano Elétrico) | `#22d3ee` | Links, destaques, CTAs |
| Primary hover | `#06b6d4` | Estados ativos |
| Sucesso | `#22c55e` | Módulos publicados, status OK |
| Atenção | `#eab308` | Módulos planejados, avisos |
| Erro | `#ef4444` | Estados críticos, destrutivo |
| Borda | `#1e293b` ou `#334155` | Divisórias, cards |
| Ring / foco | `#22d3ee` | Indicador de foco teclado |

**Ação necessária:** auditar contraste WCAG AA (≥4.5:1 texto normal, ≥3:1 texto grande) antes de definir valores finais.

## 4. Tipografia

| Elemento | Fonte | Pesos | Observação |
|----------|-------|-------|------------|
| Títulos | Outfit | 400–700 | Geométrica, moderna |
| Corpo | Source Sans 3 ou Work Sans | 400–600 | Boa leitura em longos textos |
| Código / comandos | JetBrains Mono | 400, 500 | Mono único para CLI; line-height 1.2; sem negrito que prejudique mono |
| Fallback | `system-ui`, `-apple-system`, sans-serif | — | Sem dependência exclusiva de Google Fonts |

## 5. Espaçamento e layout

- Base: 4px (escala `--space-0` a `--space-16`, já definida em `design-tokens.css`)
- Seções: `var(--space-12)` vertical, `var(--space-4)` horizontal
- Componentes: `--space-1` a `--space-4`
- Breakpoints (se houver landing HTML): 375px, 768px, 1024px, 1440px
- Medida máxima de leitura: 60–75 caracteres para parágrafos longos

## 6. Componentes (se houver interface HTML)

| Componente | Token base | Estado hover/foco |
|------------|-----------|-------------------|
| Botão primário | Ciano Elétrico `#22d3ee` | `#06b6d4`, translada -2px, sombra suave |
| Botão secundário | Azul `#3b82f6` | Opacidade / borda |
| Badge | Arredondado completo (`radius-full`) | Texto pequeno, maiúsculo opcional |
| Card | Fundo superfície, borda sutil | Borda ciano no hover, sombra suave |
| Tabela | Cabeçalho em superfície elevada | Linha zebra opcional, hover suave |
| Bloco de código | Fundo `#0f172a`, texto `#f8fafc`, borda sutil | Sem alteração de layout no hover |

## 7. Animação e movimento

- Durações: 75ms / 100ms / 150ms / 200ms / 300ms / 500ms
- Easing padrão: `cubic-bezier(0.23, 1, 0.32, 1)`
- Hover/transition: 150–300ms
- Respeitar `prefers-reduced-motion: reduce` (desabilitar animações)
- Não usar parallax ou scroll-jacking no README

## 8. Acessibilidade (checklist pré-entrega)

- [ ] Contraste de texto normal ≥ 4.5:1 contra o fundo (modo escuro)
- [ ] Contraste de texto grande ≥ 3:1
- [ ] Indicador de foco visível para navegação por teclado
- [ ] Ícones decorativos ocultos de leitores de tela (`aria-hidden`)
- [ ] Sem emoji como ícone estrutural (usar SVG consistente se houver interface)
- [ ] Touch targets ≥ 44×44 pt (se houver botões interativos)
- [ ] Responsivo em 375px, 768px, 1024px, 1440px (se houver landing HTML)
- [ ] `prefers-reduced-motion` respeitado

## 9. Tokens CSS propostos (exemplo)

```css
:root {
  /* Primitive */
  --color-cyan-500: #22d3ee;
  --color-slate-950: #08090c;
  --color-slate-900: #0f172a;
  --color-slate-50: #f8fafc;
  --color-slate-400: #94a3b8;
  --color-green-500: #22c55e;
  --color-yellow-500: #eab308;
  --color-red-500: #ef4444;

  /* Semantic */
  --color-background: var(--color-slate-950);
  --color-foreground: var(--color-slate-50);
  --color-card: var(--color-slate-900);
  --color-primary: var(--color-cyan-500);
  --color-primary-hover: #06b6d4;
  --color-success: var(--color-green-500);
  --color-warning: var(--color-yellow-500);
  --color-destructive: var(--color-red-500);
  --color-border: #1e293b;
  --color-ring: var(--color-cyan-500);

  /* Typography */
  --font-heading: 'Outfit', system-ui, sans-serif;
  --font-body: 'Source Sans 3', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;

  /* Spacing (base 4px) */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-12: 3rem;

  /* Motion */
  --duration-fast: 150ms;
  --duration-normal: 200ms;
  --ease: cubic-bezier(0.23, 1, 0.32, 1);
}
```

## 10. Próximos passos (apenas com autorização)

1. Escolher paleta final (unificar Ciano Elétrico vs Telemetria)
2. Auditar contraste com ferramenta de WCAG
3. Decidir se cria landing page HTML separada (linkada do README) ou mantém apenas Markdown
4. Se houver landing HTML, aplicar este `MASTER.md` como source of truth
5. Atualizar `docs/design-tokens.css` e/ou `docs/design-telemetry.css` para refletir o MASTER

---

**Este é um documento de proposta.** Nada foi modificado nos arquivos existentes (`docs/design-tokens.css`, `docs/design-telemetry.css`, `README.md`). Diga se deseja que eu prossiga com alguma etapa.

---
*Transparência de IA: Este projeto foi estruturado e revisado com auxílio de ferramentas de IA e testado manualmente pelo autor.*
