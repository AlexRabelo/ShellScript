# Exercícios — Módulo 09 (Arrays e Expansões)

## Exercício 1 — Inventário de servidores (Array associativo)
Crie um script que receba pares `hostname=ip` (ou use uma lista fixa de testes), armazene em um array associativo (`declare -A`) e imprima um relatório ordenado por nome de host.

## Exercício 2 — Normalização de arquivos sem `basename`/`dirname`
Dado o caminho `/opt/backups/db-prod-2026.tar.gz`, extraia usando apenas expansões de parâmetros:
1. O nome do arquivo (`db-prod-2026.tar.gz`)
2. O diretório pai (`/opt/backups`)
3. O nome sem `.gz` e sem `.tar.gz`

## Exercício 3 — Contagem de códigos HTTP com array associativo
Leia um arquivo de log no formato `IP METHOD PATH STATUS` (ou gere linhas de exemplo) e conte quantas vezes cada código HTTP (`200`, `404`, `500`) apareceu usando apenas Bash.

---

Veja a solução comentada em [`gabarito/inventario-servidores.sh`](gabarito/inventario-servidores.sh).
