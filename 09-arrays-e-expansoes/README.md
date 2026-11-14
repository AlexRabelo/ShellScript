# Módulo 09 — Arrays e Expansões de Parâmetros

Neste módulo você aprende a trabalhar com coleções de dados (arrays indexados e associativos) e manipulação nativa de strings no Bash — resolvendo transformações rápidas sem precisar disparar subshell com `sed`, `awk` ou `cut`.

> **A analogia:** se variáveis simples são gavetas individuais, **arrays indexados** são uma estante numerada (`0, 1, 2...`), **arrays associativos** são um fichário por nome (`["prod-01"]="10.0.1.10"`), e **expansões de parâmetros** são o canivete suíço que corta, substitui e define valores padrão direto na memória.

---

## Objetivos do módulo

- Declarar, percorrer e contar elementos de **arrays indexados** (`arr=(...)`, `"${arr[@]}"`, `${#arr[@]}`)
- Usar **arrays associativos** (`declare -A mapa`) para contagens e tabelas chave-valor
- Aplicar **expansões de parâmetros** para valores padrão (`:-`), remoção de prefixo/sufixo (`#`, `##`, `%`, `%%`) e substituição (`/`, `//`)
- Evitar armadilhas clássicas com `set -u` em arrays vazios

---

## Resumo de sintaxe

| Recurso | Sintaxe | Exemplo |
|---|---|---|
| Array indexado | `hosts=("web1" "web2")` | `echo "${hosts[0]}"` |
| Todos os elementos (seguro) | `"${hosts[@]}"` | `for h in "${hosts[@]}"; do ...; done` |
| Tamanho do array | `${#hosts[@]}` | `echo "Total: ${#hosts[@]}"` |
| Array associativo (Bash 4+) | `declare -A portas` | `portas["nginx"]=443` |
| Chaves do mapa | `"${!portas[@]}"` | `for svc in "${!portas[@]}"; do ...; done` |
| Valor padrão | `${VAR:-padrao}` | `PORTA="${PORTA:-8080}"` |
| Remover extensão (sufixo curto) | `${arquivo%.*}` | `app.tar.gz` → `app.tar` |
| Extrair apenas nome do arquivo | `${caminho##*/}` | `/var/log/syslog` → `syslog` |
| Substituir todas ocorrências | `${texto//antigo/novo}` | `a-b-c` → `a_b_c` |

---

## Armadilhas comuns

1. **Esquecer aspas em `"${arr[@]}"`:** sem aspas, elementos com espaço quebram em múltiplas palavras.
2. **Usar `${arr[*]}` em vez de `"${arr[@]}"`:** `*` junta tudo em uma string só; `@` preserva cada item.
3. **Esquecer `declare -A`:** sem `declare -A`, `mapa["chave"]=1` vira um array indexado comum e sobrescreve o índice `0`.
4. **`set -u` com array vazio:** em versões antigas do Bash (< 4.4), expandir `"${arr[@]}"` vazio disparava `unbound variable`; use `${arr[@]+"${arr[@]}"}` se precisar compatibilidade ampla.

---

## Conteúdo do módulo

- [`exemplos/arrays-e-expansoes.sh`](exemplos/arrays-e-expansoes.sh) — Demonstração prática de inventário SRE com arrays e expansões
- [`exercicios/README.md`](exercicios/README.md) — Enunciados dos exercícios práticos
- [`exercicios/gabarito/inventario-servidores.sh`](exercicios/gabarito/inventario-servidores.sh) — Gabarito comentado
- [`test/arrays-e-expansoes.bats`](test/arrays-e-expansoes.bats) — Testes automatizados com Bats
