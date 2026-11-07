# Links Importantes para Shell Script e Automação de Infraestrutura

Reúne recursos para aprofundar em shell script, automação de infraestrutura, SRE e práticas de engenharia de confiabilidade.

## Livros Fundamentais

### Shell Script e Bash
- [Classic Shell Scripting](https://www.oreilly.com/library/view/classic-shell-scripting/0596005954/) - Arnold Robbins & Nelson H.F. Beebe  
  *Referência essencial para entender portabilidade e limites.*
  
- [Linux Command Line and Shell Scripting Bible](https://www.wiley.com/en-us/Linux+Command+Line+and+Shell+Scripting+Bible%2C+4th+Edition-p-9781119838330) - Richard Blum & Christine Bresnahan  
  *Guia prático com foco em administração de sistemas Linux.*
  
- [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/) - Machtelt Garrels (TLDp)  
  *Tutorial gratuito e abrangente para iniciantes.*
  
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/) - Mendel Cooper (TLDp)  
  *Referência detalhada para técnicas avançadas (use com cautela - algumas práticas são desatualizadas).*

### SRE, DevOps e Infraestrutura
- [Site Reliability Engineering](https://sre.google/sre-book/) - Betsy Beyer, Chris Jones, Jennifer Petoff & Niall Richard Murphy (Google)  
  *Define a disciplina SRE.*
  
- [The Phoenix Project](https://www.itrevolution.com/book/the-phoenix-project/) - Gene Kim, Kevin Behr & George Spafford  
  *Novel que introduz os conceitos de DevOps de forma acessível.*
  
- [Accelerate](https://spear.princeton.edu/accelerate/) - Nicole Forsgren, Jez Humble & Gene Kim  
  *O que torna equipes de tecnologia de alto desempenho.*
  
- [Team Topologies](https://teamtopologies.com/) - Matthew Skelton & Manuel Pais  
  *Estruturas organizacionais para fluxo de valor rápido em tecnologia.*

### Linguagens Alternativas e Comparativas
- [Python Cookbook](https://www.oreilly.com/library/view/python-cookbook/9781449340377/) - David Beazley & Brian K. Jones  
  *Receitas práticas para quando o shell não é suficiente.*
  
- [The Go Programming Language](https://www.oreilly.com/library/view/the-go-programming-language/9780134190440/) - Alan Donovan & Brian Kernighan  
  *Excelente para entender por que Go é popular em infraestrutura.*
  
- [Designing Data-Intensive Applications](https://dataintensive.net/) - Martin Kleppmann  
  *Fundamental para entender trade-offs em sistemas de dados (relevante para escolher quando usar shell vs outras ferramentas).*

## Ferramentas Essenciais

### Para Shell Script
- [ShellCheck](https://www.shellcheck.net/)  
  *A principal ferramenta de linting para Bash - detecta erros, armadilhas e más práticas.*
  
- [bashate](https://docs.openstack.org/bashate/latest/)  
  *Linter de estilo OpenStack para Bash.*
  
- [shfmt](https://github.com/mvdan/sh)  
  *Formatador de código shell (como gofmt para Bash).*
  
- [shellharden](https://github.com/ansible/shellharden)  
  *Ferramenta para corrigir automaticamente problemas de aspas em shell scripts.*

### Para Automação e Infraestrutura
- [jq](https://jqlang.github.io/jq/)  
  *Processador de linha de comando para JSON - indispensável para trabalhar com APIs/cloud.*
  
- [yq](https://github.com/mikefarah/yq)  
  *Como jq, mas para YAML, XML e propriedades.*
  
- [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html)  
  *Substitui variáveis de ambiente em templates simples.*
  
- [gotpl](https://github.com/noogeek/gotpl)  
  *Template engine baseado em Go templates (mais poderoso que envsubst).*
  
- [helm](https://helm.sh/)  
  *Gerenciador de pacotes Kubernetes - bom exemplo de quando usar ferramentas especializadas ao invés de shell puro.*

### Observabilidade e Monitoring
- [prometheus](https://prometheus.io/)  
  *Sistema de monitoring e alerta. Útil para integrar healthchecks.*
  
- [grafana](https://grafana.com/)  
  *Plataforma de visualização que trabalha bem com Prometheus.*
  
- [vector](https://vector.dev/)  
  *Coletor de logs e métricas de alta performance - alternativa ao Fluentd/Fluent Bit.*

### Testes e Qualidade
- [bats](https://github.com/bats-core/bats-core)  
  *Bash Automated Testing System - framework de teste para Bash.*
  
- [bats-assert](https://github.com/bats-core/bats-assert)  
  *Extensão de asserções para Bats.*
  
- [bats-support](https://github.com/bats-core/bats-support)  
  *Funções de apoio para Bats.*

## Recursos Online e Comunidades

### Documentação Oficial
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)  
  *Documentação oficial do GNU Bash.*
  
- [POSIX Shell Specification](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)  
  *Especificação do shell portátil POSIX.*
  
- [Advanced Linux Programming](https://www.advancedlinuxprogramming.com/)  
  *Recurso gratuito sobre programação de sistemas Linux (chamadas de sistema, etc.).*

### Tutoriais e Guias Práticos
- [Linux Journey](https://linuxjourney.com/)  
  *Curso interativo gratuito sobre Linux.*
  
- [Explain Shell](https://www.explainshell.com/)  
  *Digite qualquer comando shell e veja explicação detalhada de cada parte.*
  
- [The Art of Command Line](https://github.com/joshuah/art-of-command-line)  
  *Coleta de dicas e truques essenciais para linha de comando.*
  
- [Bash Hackers Wiki](https://wiki.bash-hackers.org/)  
  *Wiki comunitário com exemplos e explicações práticas.*

### Comunidades e Fóruns
- [r/bash](https://www.reddit.com/r/bash/)  
  *Subreddit dedicado ao Bash e shell scripting.*
  
- [Stack Overflow - Bash Tag](https://stackoverflow.com/questions/tagged/bash)  
  *O melhor lugar para resolver problemas específicos de Bash.*
  
- [Unix & Linux Stack Exchange](https://unix.stackexchange.com/)  
  *Para perguntas mais avançadas sobre sistemas Unix/Linux.*
  
- [DevOps Subreddit](https://www.reddit.com/r/devops/)  
  *Comunidade ativa sobre práticas de DevOps e SRE.*

## Checklists e Referências Rápidas

### Armadilhas Comuns do Shell (Baseado em Bash Pitfalls)
- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls)  
  *Lista essencial de armadilhas para evitar - estude isso profundamente.*
  
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)  
  *Explicações detalhadas de cada código de erro do ShellCheck.*

### Guias de Estilo
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)  
  *Padrões de código usados internamente no Google.*
  
- [Airbnb JavaScript Style Guide (para comparação)](https://github.com/airbnb/javascript)  
  *Exemplo de guia de estilo bem estruturado em outra linguagem.*

### Referências de Portabilidade
- [POSIX Compliance Testing](https://wiki.musl-libc.org/wiki/POSIX_compliance)  
  *Entender o que é verdadeiramente portável entre diferentes shells/unixes.*
  
- [BusyBox](https://busybox.net/)  
  *Implementação leve de ferramentas Unix útil para entender o mínimo necessário.*

## Vídeos e Cursos

### Cursos Gratuitos
- [Linux Foundation - Introduction to Linux](https://training.linuxfoundation.org/training/introduction-to-linux/)  
  *Curso gratuito da Linux Foundation no edX.*
  
- [AWS Training - Shell Scripting for AWS](https://explore.skillbuilder.aws/learn/course/170/play/27249/shell-scripting-for-aws)  
  *Training específico da AWS para automação com shell.*

### Canais do YouTube
- [Linux Teaching](https://www.youtube.com/c/LinuxTeaching)  
  *Tutoriais claros e práticos sobre linha de comando e scripts.*
  
- [FreeCodeCamp.org](https://www.youtube.com/c/Freecodecamp)  
  *Cursos completos gratuitos, incluindo Linux e Bash.*
  
- [Computerphile](https://www.youtube.com/user/computerphile)  
  *Explicações aprofundadas de conceitos de ciência da computação (útil para entender fundamentos).*

## Blogs e Newsletters Especializados

### SRE e Infraestrutura
- [Google SRE Blog](https://sre.google/sre-blog/)  
  *Publicações oficiais do time de SRE do Google.*
  
- [Netflix Tech Blog](https://netflixtechblog.com/)  
  *Insights sobre como a Netflix opera em escala.*
  
- [Twitter Engineering Blog](https://blog.twitter.com/engineering/en_us)  
  *Perspectivas sobre operar uma das maiores plataformas do mundo.*
  
- [Stripe Blog](https://stripe.com/blog)  
  *Excelente para entender pagamentos em escala e infraestrutura de alta disponibilidade.*

### Shell Script e Automação
- [Dave Kerr's Blog](https://daveeddy.com/)  
  *Posts técnicos avançados sobre PowerShell e Bash (foco em Windows/Linux interop).*
  
- [Peteris Krumins' Blog](https://catonmat.net/)  
  *Artigos detalhados sobre程序设计, incluindo muitos sobre shell e perl.*
  
- [John Graham-Cumming's Blog](https://blog.jgc.org/)  
  *Posts sobre programação, história da computação e automação.*

## Quando Usar o que? Guias de Decisão

### Fluxo de Decisão para Automação
```
Problema de automação
       ↓
É apenas chamadas de sistema simples + lógica booleana? → Shell script puro
       ↓
Precisa processar JSON/YAML complexo? → jq/yq + shell OR Python
       ↓
Envolve matemática de ponto flutuante crítica? → bc/awk OR Python
       ↓
Precisa de estruturas de dados complexas ou OOP? → Python/Go
       ↓
Requisitos de performance rigorosos (<10ms latency) → Go/Rust/C
       ↓
Precisa de interface web ou API REST? → Framework adequado (ex: Flask, Gin)
       ↓
Time crítico para entrega + equipe conhece shell? → Shell (com planejamento de refatoração futura)
```

### Critérios para Escolher Linguagem de Automação
| Critério | Shell Script | Python | Go | Rust |
|----------|--------------|--------|-----|------|
| **Velocidade de desenvolvimento** | ★★★★★ | ★★★★☆ | ★★★☆☆ | ★★☆☆☆ |
| **Performance em tempo de execução** | ★★☆☆☆ | ★★★☆☆ | ★★★★★ | ★★★★★ |
| **Facilidade de depuração** | ★★☆☆☆ | ★★★★★ | ★★★★☆ | ★★★☆☆ |
| **Ecossistema de bibliotecas** | ★☆☆☆☆ | ★★★★★ | ★★★★☆ | ★★★☆☆ |
| **Facilidade de aprendizado para equipe** | ★★★★★ | ★★★★★ | ★★★☆☆ | ★★☆☆☆ |
| **Portabilidade entre sistemas** | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★★☆ |
| **Suporte a concorrência** | ★☆☆☆☆ | ★★☆☆☆ | ★★★★★ | ★★★★★ |
| **Segurança intrínseca** | ★★☆☆☆ | ★★★★☆ | ★★★★★ | ★★★★★ |
| **Manutenibilidade a longo prazo** | ★★☆☆☆ | ★★★★☆ | ★★★★★ | ★★★★★ |

*Nota: Este é um guia geral - projetos específicos podem exceder estas tendências.*

---

## Como Contribuir para Este Documento

Este recurso é mantido como parte do projeto curso-shell. Para contribuir:

1. **Fork o repositório**
2. **Faça suas adições em `referencia/links-importantes.md`**
3. **Envie um Pull Request com:**
   - Descrição clara do recurso adicionado
   - Categoria apropriada (Livros, Ferramentas, etc.)
   - Link verificável e descrição concisa
   - Justificativa de por que o recurso é valioso para profissionais de infraestrutura

**Direitos de contribuição:**
- Recursos devem ser gratuitos ou ter camadas gratuitas significativas
- Priorizar materiais em inglês (língua franca da tecnologia)
- Evitar links promocionais excessivos - foco em valor educacional/técnico
- Atualizar links quebrados quando encontrados

*Última atualização: 07/11/2026*

---
*Este documento faz parte do projeto [curso-shell](https://github.com/AlexRabelo/ShellScript) e está licenciado sob MIT License.*