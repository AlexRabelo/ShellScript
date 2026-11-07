# Quando não usar shell script

Shell script é uma ferramenta poderosa para automação de infraestrutura, mas tem limites. Este documento ajuda a escolher a ferramenta certa para cada tarefa — incluindo reconhecer quando **não** usar shell script.

Saber migrar para outra linguagem quando necessário é o que diferencia um técnico que apenas executa tarefas de alguém que projeta soluções sustentáveis.

---

## Limitações Inerentes do Shell Script

### 1. Ponto flutuante e matemática complexa
**Problema:** O Bash não suporta nativamente operações de ponto flutuante. Enquanto o POSIX shell tem aritmética inteira (`$(( ))`), operações com decimais requerem ferramentas externas como `bc` ou `awk`.

**Sinais de alerta:**
- Cálculos que exigem precisão decimal (métricas financeiras, taxas de conversão, percentuais complexos)
- Fórmulas estatísticas avançadas (desvio padrão, regressão linear)
- Simulações ou modelagens científicas
- Conversões de unidades que não sejam inteiras

**Alternativas recomendadas:**
- `bc` para cálculos simples de ponto flutuante
- `awk` quando já processando texto/largas colunas de dados
- Python para matemática complexa ou quando precisão é crítica
- Ferramentas especializadas (ex: `jq` tem suporte limitado a números, mas não é ideal para math pesado)

**Exemplo prático:**  
Calcular SLA mensal com precisão de 4 casas decimais é muito mais seguro em Python do que tentando lidar com arredondamento em shell.

### 2. Estruturas de dados complexas
**Problema:** Arrays associativos no Bash (desde 4.0) têm limitações significativas: não podem ser aninhados naturalmente, passar por referência é complicado, e serialização/desserialização é verbosa.

**Sinais de alerta:**
- Necessidade de representar objetos hierárquicos (ex: manifests Kubernetes, políticas IAM)
- Processamento de JSON profundamente aninhado (mais de 2-3 níveis)
- Construção de caches ou estado complexo entre execuções
- Manipulação de grafos ou redes de dependência

**Alternativas recomendadas:**
- **JSON + jq**: Quando o dados já vem/irá para formato JSON (comum em APIs/cloud)
- **Python**: Com dicionários nativos, listas, e bibliotecas como `pydantic` para validação
- **YAML parsers**: Quando trabalhando com configs de aplicações (ex: Helm values, Docker Compose)
- **Banco de dados leve**: SQLite para estado que precisa de consultas complexas

**Exemplo prático:**  
Gerar dinamicamente um arquivo de configuração com múltiplas seções, condicionais e herança é muito mais sustentável com Jinja2 (Python) do que tentando fazer com heredocs e sed em shell.

### 3. Performance em laços grandes e operações de I/O
**Problema:** Cada iteração de um `for` ou `while` em shell typically spawns pelo menos um novo processo. Laços são intrinsecamente lentos comparados a linguagens que executam no mesmo processo.

**Sinais de alerta:**
- Processamento de arquivos de log > 10MB ou > 100k linhas
- Varredura de sistemas de arquivos com milhões de arquivos (ex: `/var/log/*/*/*`)
- Operações que envolvem milhares de chamadas a comandos externos em laços
- Scripts que rodam em loops de monitoramento com frequência alta (ex: a cada 5 segundos)

**Alternativas recomendadas:**
- **Ferramentas de linha especializadas**: `awk`, `sed`, `grep`, `cut` são otimizados para processamento de fluxo
- **xargs/paralelo**: Para paralelizar tarefas de I/O quando seguro
- **Linguagens compiladas/interpretadas**: Quando a lógica por item é complexa
- **Buffering e batching**: Processar em chunks ao invés de item a item

**Exemplo prático:**  
Analisar 1GB de logs nginx para identificar padrões de ataque é muito mais eficiente com `awk` ou `goaccess` do que com um `while read line` em shell.

### 4. Falta de tipagem e segurança em escala
**Problema:** Variáveis não tipadas no shell levam a bugs silenciosos que só se manifestam em condições específicas de dados. A falta de escopo lexical adequado (antes de funções nomeadas em Bash 4.0+) dificultava modularidade.

**Sinais de alerta:**
- Scripts que excedem 300 linhas de código funcional
- Necessidade de validar tipos de entrada rigorosamente (ex: garantir que um parâmetro é um IP válido, não apenas uma string)
- Arquitetura com muitos scripts interdependentes que compartilham estado
- Requisitos de segurança onde injeção de comando é um risco real (ex: processamento de entrada do usuário)

**Alternativas recomendadas:**
- **Linguagens com sistema de tipos**: Go, Rust, TypeScript para prevenir classes inteiras de bugs em tempo de compilação
- **Frameworks com validação de schema**: Como Pydantic (Python) ou Joi (Node.js)
- **Arquitetura de microserviços**: Isolando componentes com fronteiras claras
- **Práticas de defesa**: Uso rigoroso de aspas, validação de entrada, e evitando `eval` a todo custo

**Exemplo prático:**  
Construir um sistema de plugins onde cada plugin pode adicionar funcionalidade ao núcleo é muito mais seguro e testável em Go com interfaces do que tentando fazer com sourcing dinâmico de scripts shell.

---

## Sinais de que é hora de migrar para outra linguagem

Considere migrar quando você observar **três ou mais** destes indicadores:

| Indicador | Descrição | Threshold sugerido |
|-----------|-----------|-------------------|
| **Tamanho do código** | Linhas de código funcional (excluindo comentários, estrutura de erro) | > 250-300 linhas |
| **Complexidade de dados** | Necessidade de estruturas aninhadas além de 2 níveis | JSON/YAML com profundidade > 2 |
| **Volume de processamento** | Taxa de linhas/arquivos processados por segundo | > 1k linhas/sec ou > 100 arquivos/sec |
| **Dependências externas** | Precisa de bibliotecas não disponíveis como comandos de linha | Processamento de imagens, criptografia avançada, ML |
| **Estado persistente** | Precisa manter estado complexo entre execuções | Mais que simples contadores ou flags |
| **Requisitos de performance** | Latência crítica (< 100ms) ou throughput alto | Operações que devem ser sub-segundo |
| **Padronização da equipe** | Organização já adotou outra linguagem para novos projetos | >50% de automação nova em Python/Go |
| **Dificuldade de teste** | Testes unitários são complexos ou lentos de escrever | >50% do esforço em setup/mock de teste |

---

## Estratégias de Transição Gradual

### Estratégia 1: Shell como Orquestrador de Alto Nível
**Princípio:** Mantenha o shell para tarefas de nível de sistema (verificação de pré-requisitos, chamada de serviços, gerenciamento de ciclo de vida) e delegue a lógica complexa para scripts especializados.

**Quando usar:**  
- Scripts de deploy/inicialização
- Hooks de CI/CD
- Scripts de diagnóstico de emergência
- Orquestração de múltiplos microserviços

**Exemplo de implementação:**
```bash
#!/usr/bin/env bash
# deploy-app.sh - Orquestração de deploy com delegação de lógica complexa

set -Eeuo pipefail

# Verificações de pré-requisito (shell é ideal aqui)
requisitos=("kubectl" "jq" "git")
for cmd in "${requisitos[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Erro: $cmd não encontrado"; exit 1; }
done

# Lógica complexa delegada para Python
CONFIG=$(python3 -c "
import yaml, json, sys
with open('values.yaml') as f:
    data = yaml.safe_load(f)
data['replicaCount'] = int(sys.argv[1])
print(json.dumps(data))
" "$REPLICAS")

# Uso do resultado no shell (ideal para chamadas de linha)
echo "$CONFIG" | kubectl apply -f -
```

### Estratégia 2: Microserviços de Automação Leve
**Princípio:** Divida um monolito de automação em pequenos serviços independentes, cada um implementado na linguagem mais adequada para sua função específica.

**Padrões de comunicação:**
- **Arquivos de fila**: Diretórios com arquivos de tarefa (ex: `/var/automation/queue/`)
- **Socets Unix**: Para comunicação de baixa latência entre componentes no mesmo host
- **Mensageria leve**: Redis, RabbitMQ ou até mesmo tabelas de banco de dados simples
- **APIs REST/HTTP**: Quando a comunicação atravessa hosts ou precisa de padrões estabelecidos

**Exemplo de arquitetura:**
```
[Health Checker] --> (Redis Queue) --> [Log Processor] --> (Alert Router) --> [Notification Service]
     (Shell)                  (Python/Pandas)          (Go)                  (Shell + webhook)
```
- Health Checker: Shell (ideal para chamadas rápidas de sistema)
- Log Processor: Python (pandas para análise estatística)
- Alert Router: Go (alta performance de roteamento)
- Notification Service: Shell (chamada direta a webhooks é simples e eficaz)

### Estratégia 3: Reescrita Funcional por Funcionalidade
**Princípio:** Priorize a reescrita com base em risco, frequência de uso e complexidade, mantendo regressão testada durante todo o processo.

**Passos de implementação:**
1. **Mapeie os componentes**: Liste todos os scripts e módulos do seu sistema de automação
2. **Avalie risco e complexidade**: Para cada componente, atribua pontuação em:
   - Frequência de execução (quanto mais frequente, maior prioridade para refatorar)
   - Histórico de incidentes (componentes que causaram falhas passadas)
   - Complexidade de lógica (quantas condições de negócio existem)
   - Dificuldade de teste (quão fácil é escrever testes automatizados)
3. **Priorize**: Comece pelos componentes com maior soma de pontuação
4. **Mantenha contrato**: Certifique-se de que a nova implementação aceita os mesmos inputs e produz os mesmos outputs (ou melhorados)
5. **Teste de regressão**: Execute a suite de testes existentes contra a nova implementação
6. **Monitore pós-deploy**: Acompanhe métricas de performance e taxa de erro após a troca

**Exemplo de priorização:**  
Em um típico ambiente de SRE:
1. **Alta prioridade**: Scripts de detecção de anomalia (alta complexidade, baixo histórico de teste, alto impacto se falhar)
2. **Média prioridade**: Scripts de backup (baixa frequência, alto impacto se falhar, mas geralmente bem testados)
3. **Baixa prioridade**: Scripts de rotina de limpeza (baixa complexidade, alta frequência, baixo impacto se falhar momentaneamente)

---

## Bibliografia e Leituras Recomendadas

### Livros
- _Classic Shell Scripting_ by Arnold Robbins and Nelson H.F. Beebe - Excelente para entender os limites e poder do POSIX shell
- _The Linux Programming Interface_ by Michael Kerrisk - Para entender chamadas de sistema subjacentes que o shell abstrai
- _Site Reliability Engineering_ by Betsy Beyer et al. (Capítulo sobre gerenciamento de toil) - Contexto SRE para automação
- _Effective Shell_ by David Both - Boas práticas modernas para Bash

### Artigos e Blogs
- [When to Use (and Not Use) Shell Scripts](https://opensource.com/article/20/10/shell-scripts) - Opensource.com
- [Shell Scripting Considered Harmful](https://lea.verou.me/2016/10/shell-scripting-considered-harmful/) - Lea Verou (contraperspectiva válida)
- [The Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls) - Wiki essencial para evitar armadilhas
- [Choosing the Right Tool for the Job](https://techblog.bozho.net/choosing-the-right-tool-for-the-job/) - Bozhidar Bozhanov

### Ferramentas de Avaliação
- [ShellCheck](https://www.shellcheck.net/) - Não apenas para erros, mas para identificar padrões que sugerem complexidade excessiva
- [Loc](https://github.com/cgag/loc) - Contador de linhas de código que ignora comentários e espaços em branco
- [SonarQube](https://www.sonarqube.org/) - Com plugins para detectar complexidade e duplicação em scripts

---

## Conclusão

Shell script continua sendo peça fundamental da automação de infraestrutura. Seu valor é maximizado quando usado dentro do domínio onde funciona bem. Desenvolver o julgamento técnico para saber quando migrar para Python, Go ou outra ferramenta é o que transforma um bom administrador de sistemas em um excelente engenheiro de sistemas.