# Quiz: Módulo 10 — Scripts de Produção

**Tempo:** 10 min | **Pontuação:** 10 pts | **Passe:** 7/10

---

## 1. set -Eeuo pipefail (1 pt)
O que cada flag faz? Associe:

| Flag | Efeito |
|------|--------|
| `-E` | a) Aborta em variável não definida |
| `-e` | b) Herda trap ERR em funções/subshells |
| `-u` | c) Pipeline falha se qualquer comando falhar |
| `-o pipefail` | d) Aborta em comando com exit ≠ 0 |

- [ ] E→b, e→d, u→a, pipefail→c
- [ ] E→a, e→b, u→c, pipefail→d
- [ ] E→d, e→c, u→b, pipefail→a
- [ ] E→c, e→a, u→d, pipefail→b

---

## 2. trap EXIT (1 pt)
Quando o `trap 'cleanup' EXIT` executa?

- [ ] Só em exit 0
- [ ] Só em exit ≠ 0
- [ ] **Sempre** ao sair do script (sucesso, erro, signal)
- [ ] Só em signal SIGTERM

---

## 3. flock anti-concorrência (1 pt)
```bash
exec 9> /var/lock/meuscript.lock
flock -n 9 || { echo "Já rodando"; exit 1; }
```
O que `-n` faz?

- [ ] Bloqueia até conseguir
- [ ] **Não bloqueia** — falha imediatamente se lock ocupado
- [ ] Cria lock compartilhado
- [ ] Remove lock anterior

---

## 4. Dry-run pattern (1 pt)
Qual a estrutura correta para função `run()` com dry-run?

- [ ] `run() { if [[ $DRY_RUN -eq 1 ]]; then echo "[DRY-RUN] $*"; else "$@"; fi; }`
- [ ] `run() { [[ $DRY_RUN ]] && echo "$*" || "$@"; }`
- [ ] `run() { if $DRY_RUN; then "$@"; else echo "[DRY-RUN] $*"; fi; }`
- [ ] `run() { $DRY_RUN && echo "[DRY-RUN] $*" || "$@"; }`

---

## 5. Códigos de saída padronizados (1 pt)
Qual convenção para: "Erro de uso / argumentos inválidos"?

- [ ] 0
- [ ] 1
- [ ] 2
- [ ] 3

---

## 6. Variável vazia com set -u (1 pt)
```bash
set -u
echo "$UNDEFINED_VAR"
```
O que acontece?

- [ ] Imprime linha vazia
- [ ] **Erro: unbound variable** e aborta script
- [ ] Imprime "UNDEFINED_VAR"
- [ ] Comportamento indefinido

---

## 7. Lock file location (1 pt)
Onde **não** colocar lock file para produção?

- [ ] `/var/lock/meuscript.lock`
- [ ] `/tmp/meuscript.lock`
- [ ] `/run/lock/meuscript.lock`
- [ ] `/var/run/meuscript.lock`

---

## 8. Logging levels (1 pt)
Qual nível deve ir para **stderr**?

- [ ] INFO
- [ ] DEBUG
- [ ] **ERRO, AVISO**
- [ ] OK

---

## 9. Validação de número (1 pt)
Qual forma **correta** valida porta 1-65535?

- [ ] `[[ $port -ge 1 && $port -le 65535 ]]`
- [ ] `(( port >= 1 && port <= 65535 ))`
- [ ] Ambas funcionam
- [ ] `test $port -ge 1 -a $port -le 65535`

---

## 10. Idempotência (1 pt)
Script idempotente significa:

- [ ] Roda rápido
- [ ] **Rodar múltiplas vezes produz mesmo resultado sem efeitos colaterais**
- [ ] Não usa variáveis
- [ ] Só usa comandos builtin

---

## Gabarito
1. A | 2. C | 3. B | 4. A | 5. C | 6. B | 7. B | 8. C | 9. C | 10. B

---

## Critério de Avaliação
- **9-10:** Pronto para escrever scripts de produção
- **7-8:** Revisar trap, flock, dry-run
- **<7:** Releia módulo; foque em strict mode e idempotência