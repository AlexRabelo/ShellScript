# Gabarito - Módulo 15: Projeto Final (SRE Toolkit)

---

## Exercício 1: Entendendo a Arquitetura (Análise)

**Respostas:**

1. **Ponto de entrada principal:** `bin/sre-toolkit` - É o script principal que:
   - Define `TOOLKIT_ROOT`, `LIB_DIR`, `COMANDOS_DIR`
   - Carrega configuração se existir (`source "$CONFIG_FILE"`)
   - Carrega bibliotecas compartilhadas (`lib/log.sh`, `lib/valida.sh`, `lib/alerta.sh`, `lib/util.sh`)
   - Define array associativo `SUBCOMANDOS` mapeando nomes para scripts em `comandos/`
   - Faz parse de opções globais (-c, -v, -n, -h)
   - Valida subcomando e executa via `exec "${SUBCOMANDOS[$subcomando]}"`

2. **Bibliotecas compartilhadas:** Os subcomandos fazem `source "${LIB_DIR}/log.sh"` etc. no início. Como são executados via `exec` pelo script principal, herdam as funções e variáveis exportadas (SCRIPT_NAME, LOG_FILE, TOOLKIT_ROOT, LIB_DIR, COMANDOS_DIR, CONFIG_FILE, JSON_OUTPUT, VERBOSE, DRY_RUN).

3. **Subcomandos para cada caso:**
   a) `sre-toolkit saude` - Relatório completo de saúde
   b) `sre-toolkit backup -r 7 /var/www /backup` - Backup rotativo com retenção 7
   c) `sre-toolkit incidente --coleta-completa --dir /tmp/incidente-$(date +%F)` - Diagnóstico completo
   d) `sre-toolkit health -j https://api.exemplo.com/health` - Healthcheck HTTP com JSON

4. **DRY_RUN:** Variável que controla simulação. Definida como `0` por padrão no script principal, pode ser ativada com `-n|--dry-run` (opção global). Quando `1`, a função `run()` em `lib/util.sh` apenas loga `[DRY-RUN] comando` sem executar. Usada em `backup.sh`, `disco.sh`, `incidente.sh`.

---

## Exercício 2: Instalação e Configuração

**Passos realizados:**

```bash
# 1. Criar diretório bin no PATH
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 2. Copiar executável principal
cp 15-projeto-final/sre-toolkit/bin/sre-toolkit ~/bin/
chmod +x ~/bin/sre-toolkit

# 3. Copiar bibliotecas e comandos
mkdir -p ~/.local/share/sre-toolkit
cp -r 15-projeto-final/sre-toolkit/lib ~/.local/share/sre-toolkit/
cp -r 15-projeto-final/sre-toolkit/comandos ~/.local/share/sre-toolkit/

# 4. Criar configuração
mkdir -p ~/.config
cat > ~/.config/sre-toolkit.conf << 'EOF'
ALERT_WEBHOOK_URL="https://webhook.site/seu-id-unico"
BACKUP_RETENCAO_DIAS=14
HEALTHCHECK_TIMEOUT=10
EOF

# 5. Testar
sre-toolkit saude
sre-toolkit saude -j | jq .
```

**Verificação:** Ambos comandos devem executar sem erro e mostrar relatório de saúde.

---

## Exercício 3: Subcomando `saude` - Relatórios e JSON

**1. Execução texto:**
```bash
$ sre-toolkit saude
=== SAÚDE DO SERVIDOR ===
Hostname: meu-host
Uptime: 3600s
Kernel: 6.1.0
Distro: Ubuntu 24.04

CPU: 15% (4 cores) | Carga: 0.5 0.3 0.2

RAM: 45% (4.2GB/9.1GB) | Swap: 0%

DISCO:
/dev/sda1: 60% (50GB/100GB) em /

Processos: 180 total (2 running, 175 sleeping, 0 zombie)
```

**2. Salvar JSON:**
```bash
sre-toolkit saude -j > saude.json
```

**3. Extrair com jq:**
```bash
jq '.cpu.uso_percentual' saude.json       # ex: 15
jq '.memoria.uso_percentual' saude.json   # ex: 45
jq '.disco[0].uso_percentual' saude.json  # ex: 60
```

**4. Script monitora-saude.sh:**
```bash
#!/usr/bin/env bash
# monitora-saude.sh - Monitora saúde e alerta se thresholds excedidos

set -Eeuo pipefail

THRESHOLD_CPU=80
THRESHOLD_RAM=90
THRESHOLD_DISK=90
INTERVALO=60

main() {
    echo "Iniciando monitoramento (CPU>${THRESHOLD_CPU}%, RAM>${THRESHOLD_RAM}%, DISK>${THRESHOLD_DISK}%)..."
    echo "Pressione Ctrl+C para parar"
    echo
    
    while true; do
        local json
        json=$(sre-toolkit saude -j 2>/dev/null)
        
        local cpu ram disk
        cpu=$(echo "$json" | jq -r '.cpu.uso_percentual')
        ram=$(echo "$json" | jq -r '.memoria.uso_percentual')
        disk=$(echo "$json" | jq -r '.disco[0].uso_percentual // 0')
        
        local alerta=0
        (( cpu > THRESHOLD_CPU )) && { echo "[$(date '+%F %T')] ALERTA: CPU em ${cpu}%"; alerta=1; }
        (( ram > THRESHOLD_RAM )) && { echo "[$(date '+%F %T')] ALERTA: RAM em ${ram}%"; alerta=1; }
        (( disk > THRESHOLD_DISK )) && { echo "[$(date '+%F %T')] ALERTA: Disco em ${disk}%"; alerta=1; }
        
        if (( alerta == 0 )); then
            echo "[$(date '+%F %T')] OK - CPU:${cpu}% RAM:${ram}% DISK:${disk}%"
        fi
        
        sleep "$INTERVALO"
    done
}

main "$@"
```

---

## Exercício 4: Subcomando `disco` - Análise e Limpeza

**1. Criar estrutura de teste:**
```bash
mkdir -p /tmp/teste-disco/{logs,temp,cache}
echo "recente" > /tmp/teste-disco/logs/app.log
touch -d "40 days ago" /tmp/teste-disco/logs/old.log
touch -d "45 days ago" /tmp/teste-disco/temp/temp.txt
touch -d "60 days ago" /tmp/teste-disco/cache/cache.dat
```

**2. Análise apenas (sem limpeza):**
```bash
$ sre-toolkit disco --dir /tmp/teste-disco --dias 30
=== ANÁLISE DE DISCO: /tmp/teste-disco ===
Diretório: /tmp/teste-disco
Limite de idade: 30 dias
Total de arquivos: 4
Tamanho total: 0 B
Arquivos com mais de 30 dias: 3
Tamanho desses arquivos: 0 B

Arquivos removidos na limpeza: 0
```

**3. Com limpeza:**
```bash
$ sre-toolkit disco --dir /tmp/teste-disco --dias 30 --limpeza
=== ANÁLISE DE DISCO: /tmp/teste-disco ===
...
Arquivos removidos na limpeza: 3
```

**4. JSON output:**
```bash
$ sre-toolkit disco --dir /tmp/teste-disco --dias 30 -j | jq .
{
  "diretorio": "/tmp/teste-disco",
  "dias_limite": "30",
  "total_arquivos": 4,
  "total_tamanho_bytes": 0,
  "arquivos_mais_antigos": 3,
  "tamanho_antigo_bytes": 0,
  "detalhes": [
    {"path": "/tmp/teste-disco/logs/old.log", "size_bytes": 0, "idade_dias": 40},
    {"path": "/tmp/teste-disco/temp/temp.txt", "size_bytes": 0, "idade_dias": 45},
    {"path": "/tmp/teste-disco/cache/cache.dat", "size_bytes": 0, "idade_dias": 60}
  ],
  "limpeza": {"arquivos_removidos": 3},
  "timestamp": "2026-10-15T14:30:00Z"
}
```

**Explicação:** Foram removidos 3 arquivos com mais de 30 dias (old.log, temp.txt, cache.dat). O arquivo app.log (1 dia) foi mantido.

---

## Exercício 5: Subcomando `backup` - Backup Rotativo

**1-2. Preparação:**
```bash
mkdir -p /tmp/dados/{site,db} /tmp/backups
echo "conteúdo do site" > /tmp/dados/site/index.html
echo "dados db" > /tmp/dados/db/dados.sql
```

**3. Primeiro backup:**
```bash
$ sre-toolkit backup -r 3 /tmp/dados /tmp/backups
criando backup: /tmp/backups/backup-2026-10-15-143000.tar.gz
gerando checksum SHA256
backup criado com sucesso
aplicando retenção de 3 backups
```

**4-5. Após 5 backups (simulados com dry-run ou aguardando):**
```bash
$ ls -la /tmp/backups/
total 20
-rw-r--r-- 1 user user  178 Oct 15 14:34 backup-2026-10-15-143400.tar.gz
-rw-r--r-- 1 user user   89 Oct 15 14:34 backup-2026-10-15-143400.tar.gz.sha256
-rw-r--r-- 1 user user  178 Oct 15 14:33 backup-2026-10-15-143300.tar.gz
-rw-r--r-- 1 user user   89 Oct 15 14:33 backup-2026-10-15-143300.tar.gz.sha256
-rw-r--r-- 1 user user  178 Oct 15 14:32 backup-2026-10-15-143200.tar.gz
-rw-r--r-- 1 user user   89 Oct 15 14:32 backup-2026-10-15-143200.tar.gz.sha256
```
*Nota: A implementação atual não remove backups antigos automaticamente - isso seria implementado na versão completa usando `ls -t | tail -n +4 | xargs rm -f`.*

**6. Verificação de integridade:**
```bash
$ sha256sum -c /tmp/backups/backup-*.sha256
/tmp/backups/backup-2026-10-15-143200.tar.gz: OK
/tmp/backups/backup-2026-10-15-143300.tar.gz: OK
/tmp/backups/backup-2026-10-15-143400.tar.gz: OK
```

---

## Exercício 6: Subcomando `health` - Healthchecks

**1-2. Arquivos de configuração:**
```bash
cat > servicos.txt << 'EOF'
sshd
systemd-journald
cron
EOF

cat > endpoints.txt << 'EOF'
https://httpbin.org/get
https://httpbin.org/status/200
https://httpbin.org/status/500
EOF
```

**3. Execução texto:**
```bash
$ sre-toolkit health -s servicos.txt -e endpoints.txt
=== HEALTH CHECK ===
Total verificações: 6
OK: 5
FALHA: 1

Verificações com falha:
Endpoints:
  https://httpbin.org/status/500
```

**4. JSON output:**
```bash
$ sre-toolkit health -j -s servicos.txt -e endpoints.txt | jq .
{
  "timestamp": "2026-10-15T14:35:00Z",
  "total": 6,
  "ok": 5,
  "fail": 1,
  "verificacoes": [
    {"nome": "sshd", "tipo": "systemd", "status": "ok"},
    {"nome": "systemd-journald", "tipo": "systemd", "status": "ok"},
    {"nome": "cron", "tipo": "systemd", "status": "ok"},
    {"url": "https://httpbin.org/get", "tipo": "http", "status": "ok"},
    {"url": "https://httpbin.org/status/200", "tipo": "http", "status": "ok"},
    {"url": "https://httpbin.org/status/500", "tipo": "http", "status": "fail"}
  ]
}
```

**5. Script healthcheck-loop.sh:**
```bash
#!/usr/bin/env bash
# healthcheck-loop.sh - Healthcheck com coleta de incidente em falha

set -Eeuo pipefail

SERVICOS="servicos.txt"
ENDPOINTS="endpoints.txt"
MAX_CICLOS=3
INTERVALO=30
CICLO=0

main() {
    echo "Iniciando healthcheck loop (máx $MAX_CICLOS ciclos, intervalo ${INTERVALO}s)..."
    
    while (( CICLO < MAX_CICLOS )); do
        ((CICLO++))
        echo "=== Ciclo $CICLO/$MAX_CICLOS - $(date '+%F %T') ==="
        
        local json
        json=$(sre-toolkit health -j -s "$SERVICOS" -e "$ENDPOINTS" 2>/dev/null)
        local fail
        fail=$(echo "$json" | jq -r '.fail')
        
        if (( fail > 0 )); then
            local dir="/tmp/incidente-$(date +%F-%H%M%S)"
            echo "Falhas detectadas ($fail). Coletando incidente em $dir..."
            sre-toolkit incidente --coleta-completa --dir "$dir"
            echo "Incidente coletado. Compactando..."
            tar -czf "${dir}.tar.gz" -C /tmp "$(basename "$dir")"
            echo "Arquivo: ${dir}.tar.gz"
        else
            echo "Todas verificações OK!"
        fi
        
        (( CICLO < MAX_CICLOS )) && sleep "$INTERVALO"
    done
    
    echo "Monitoramento finalizado."
}

main "$@"
```

---

## Exercício 7: Subcomando `logs` - Análise de Logs

**1. Criar log nginx de teste:**
```bash
bash 08-processamento-de-texto/exemplos/top-ips-nginx.sh /tmp/test.log 5
```

**2. Análise nginx:**
```bash
$ sre-toolkit logs -f nginx /tmp/test.log
=== /tmp/test.log ===
Formato: nginx
Linhas: 13
Palavras: 117
Bytes: 1234
```

**3. JSON:**
```bash
$ sre-toolkit logs -f json -j /tmp/test.log | jq .
{
  "timestamp": "2026-10-15T14:40:00Z",
  "analises": [
    {
      "arquivo": "/tmp/test.log",
      "formato": "nginx",
      "linhas": 13,
      "palavras": 117,
      "bytes": 1234,
      "timestamp": "2026-10-15T14:40:00Z"
    }
  ]
}
```

**4. Criar log JSON:**
```bash
cat > /tmp/app.json.log << 'EOF'
{"timestamp":"2026-10-15T10:00:00Z","level":"INFO","msg":"User login","user_id":123}
{"timestamp":"2026-10-15T10:00:01Z","level":"ERROR","msg":"DB connection failed","error":"timeout"}
{"timestamp":"2026-10-15T10:00:02Z","level":"INFO","msg":"Retry successful","user_id":123}
{"timestamp":"2026-10-15T10:00:03Z","level":"WARN","msg":"High latency","latency_ms":1500}
EOF
```

**5. Análise JSON:**
```bash
$ sre-toolkit logs -f json /tmp/app.json.log
=== /tmp/app.json.log ===
Formato: json
Linhas: 4
Palavras: 38
Bytes: 356
```

---

## Exercício 8: Subcomando `incidente` - Coleta de Diagnóstico

**1. Coleta básica:**
```bash
$ sre-toolkit incidente --dir /tmp/incidente-teste
=== COLETA DE INCIDENTE CONCLUÍDA ===
Diretório: /tmp/incidente-teste
Tipo: Básica
```

**2. Arquivos gerados:**
```bash
$ ls -la /tmp/incidente-teste/
total 80
-rw-r--r-- 1 user user  500 system_info.txt
-rw-r--r-- 1 user user 1200 os_info.txt
-rw-r--r-- 1 user user  800 hostname_info.txt
-rw-r--r-- 1 user user 5000 top.txt
-rw-r--r-- 1 user user 2000 top_cpu.txt
-rw-r--r-- 1 user user 2000 top_mem.txt
-rw-r--r-- 1 user user  500 disk_usage.txt
-rw-r--r-- 1 user user  300 memory_usage.txt
-rw-r--r-- 1 user user  800 network_ports.txt
-rw-r--r-- 1 user user 2000 services_running.txt
-rw-r--r-- 1 user user  200 services_failed.txt
-rw-r--r-- 1 user user 5000 journald_recent.txt
```

**3. system_info.txt:**
```bash
$ cat /tmp/incidente-teste/system_info.txt
Linux meu-host 6.1.0 #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux
```

**4. Coleta completa:**
```bash
$ sre-toolkit incidente --coleta-completa --dir /tmp/incidente-completo
=== COLETA DE INCIDENTE CONCLUÍDA ===
Diretório: /tmp/incidente-completo
Tipo: Completa
```

**5-6. Compactar e verificar tamanho:**
```bash
$ tar -czf /tmp/incidente-completo.tar.gz -C /tmp incidente-completo
$ du -h /tmp/incidente-completo.tar.gz
2.5M    /tmp/incidente-completo.tar.gz
```

---

## Exercício 9: Extensão - Novo Subcomando `docker`

**Arquivo: `comandos/docker.sh`**
```bash
#!/usr/bin/env bash
#
# comandos/docker.sh - Gerenciamento de containers Docker
#
# Uso: sre-toolkit docker [-j|--json] [-v|--verbose] [--limpeza] [--stats] [-h|--help]

set -Eeuo pipefail

source "${LIB_DIR}/log.sh"
source "${LIB_DIR}/valida.sh"

JSON_OUTPUT=0
VERBOSE=0
FAZER_LIMPEZA=0
MOSTRAR_STATS=0

usage() {
    cat <<EOF
docker - Gerenciamento de containers Docker

Uso: sre-toolkit docker [-j|--json] [-v|--verbose] [--limpeza] [--stats] [-h|--help]

Opções:
  -j, --json       Saída JSON
  -v, --verbose    Inclui detalhes
  --limpeza        Remove images/containers/volumes dangling (docker system prune)
  --stats          Mostra estatísticas de recursos (CPU/Memória)
  -h, --help       Exibe ajuda
EOF
}

tem_docker() {
    command -v docker >/dev/null 2>&1 || { log_erro "Docker não instalado"; return 1; }
}

lista_containers() {
    local json_output="$1"
    tem_docker || return 1
    
    local containers_json
    containers_json=$(docker ps -a --format '{{json .}}' 2>/dev/null || echo "")
    
    if [[ -z "$containers_json" ]]; then
        if (( json_output == 1 )); then
            echo "[]"
        else
            echo "Nenhum container encontrado"
        fi
        return 0
    fi
    
    local results="[]"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if (( json_output == 1 )); then
            results=$(echo "$results" | jq -c --argjson c "$line" '. + [$c]')
        else
            local name status image
            name=$(echo "$line" | jq -r '.Names')
            status=$(echo "$line" | jq -r '.Status')
            image=$(echo "$line" | jq -r '.Image')
            printf "%-30s %-20s %s\n" "$name" "$status" "$image"
        fi
    done <<< "$containers_json"
    
    if (( json_output == 1 )); then
        echo "$results"
    fi
}

stats_containers() {
    local json_output="$1"
    tem_docker || return 1
    
    local stats_json
    stats_json=$(docker stats --no-stream --format '{{json .}}' 2>/dev/null || echo "")
    
    if [[ -z "$stats_json" ]]; then
        if (( json_output == 1 )); then
            echo "[]"
        else
            echo "Nenhum container rodando"
        fi
        return 0
    fi
    
    local results="[]"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if (( json_output == 1 )); then
            results=$(echo "$results" | jq -c --argjson s "$line" '. + [$s]')
        else
            local name cpu mem
            name=$(echo "$line" | jq -r '.Name')
            cpu=$(echo "$line" | jq -r '.CPUPerc')
            mem=$(echo "$line" | jq -r '.MemUsage')
            printf "%-30s CPU: %-10s MEM: %s\n" "$name" "$cpu" "$mem"
        fi
    done <<< "$stats_json"
    
    if (( json_output == 1 )); then
        echo "$results"
    fi
}

limpa_dangling() {
    tem_docker || return 1
    
    log_info "Executando limpeza Docker (docker system prune -f)..."
    run docker system prune -f
    
    if (( JSON_OUTPUT == 1 )); then
        jq -n --arg msg "Limpeza concluída" --arg ts "$(timestamp_iso)" \
            '{status: "ok", mensagem: $msg, timestamp: $ts}'
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            --limpeza) FAZER_LIMPEZA=1; shift ;;
            --stats) MOSTRAR_STATS=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) log_erro "Opção desconhecida: $1"; usage >&2; exit 2 ;;
        esac
    done

    log_info "início (json=$JSON_OUTPUT, limpeza=$FAZER_LIMPEZA, stats=$MOSTRAR_STATS)"

    if (( FAZER_LIMPEZA == 1 )); then
        limpa_dangling
    elif (( MOSTRAR_STATS == 1 )); then
        stats_containers "$JSON_OUTPUT"
    else
        lista_containers "$JSON_OUTPUT"
    fi

    log_info "fim"
}

main "$@"
```

**Testes:**
```bash
# Lista containers
sre-toolkit docker
sre-toolkit docker -j | jq .

# Stats (requer containers rodando)
sre-toolkit docker --stats

# Limpeza (dry-run primeiro)
sre-toolkit docker --limpeza -n
sre-toolkit docker --limpeza
```

---

## Exercício 10: Integração Completa - Pipeline de Monitoramento

**Arquivo: `monitoramento-completo.sh`**
```bash
#!/usr/bin/env bash
#
# monitoramento-completo.sh - Pipeline completo de monitoramento SRE
#
# Uso: monitoramento-completo.sh [-j|--json] [-n|--dry-run] [-v|--verbose] [-c|--config ARQ] [-h|--help]
#
# Orquestra: healthcheck -> incidente se falha -> analisa logs -> verifica disco -> alerta -> relatório JSON

set -Eeuo pipefail

# --- Configuração ---
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

JSON_OUTPUT=0
DRY_RUN=0
VERBOSE=0
CONFIG_FILE=""
SERVICOS_FILE="servicos.txt"
ENDPOINTS_FILE="endpoints.txt"
LOG_FILES=()
DISCO_DIR="/tmp"
DISCO_DIAS=30
ALERT_WEBHOOK=""

# --- Log ---
log() {
    local nivel="$1"; shift
    local msg="$(date '+%F %T') [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    case "$nivel" in
        ERRO|AVISO) printf '%s\n' "$msg" >&2 ;;
        DEBUG)      (( VERBOSE == 1 )) && printf '%s\n' "$msg" ;;
        *)          (( JSON_OUTPUT == 0 )) && printf '%s\n' "$msg" ;;
    esac
}
log_info()  { log INFO "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO "$@"; }
log_debug() { log DEBUG "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; (( c != 0 )) && log_erro "terminou com falha (código $c)" || log_info "terminou com sucesso"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM
trap 'log_erro "erro linha ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Utilidades ---
run() {
    if (( DRY_RUN == 1 )); then
        log_info "[DRY-RUN] $*"
    else
        log_debug "executando: $*"
        "$@"
    fi
}

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando obrigatório: $1" 3; }

usage() {
    sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
}

carrega_config() {
    [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]] || return 0
    log_info "Carregando configuração: $CONFIG_FILE"
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    ALERT_WEBHOOK="${ALERT_WEBHOOK_URL:-}"
}

# --- Funções do Pipeline ---

# 1. Healthcheck
executa_healthcheck() {
    log_info "=== 1/6: Healthcheck dos serviços ==="
    
    local json
    json=$(run sre-toolkit health -j -s "$SERVICOS_FILE" -e "$ENDPOINTS_FILE" 2>/dev/null) || {
        log_erro "Falha ao executar healthcheck"
        echo '{"erro": "healthcheck falhou"}'
        return 1
    }
    
    local fail
    fail=$(echo "$json" | jq -r '.fail // 0')
    echo "$json"
    return $(( fail > 0 ? 1 : 0 ))
}

# 2. Coleta incidente se houver falhas
executa_incidente() {
    local health_json="$1"
    local fail
    fail=$(echo "$health_json" | jq -r '.fail // 0')
    
    (( fail == 0 )) && { log_info "Nenhuma falha no healthcheck, pulando coleta de incidente"; echo "{}"; return 0; }
    
    log_info "=== 2/6: Coletando diagnóstico de incidente ==="
    
    local dir="/tmp/incidente-$(date +%F-%H%M%S)"
    local json
    json=$(run sre-toolkit incidente --coleta-completa --dir "$dir" -j 2>/dev/null) || {
        log_erro "Falha ao coletar incidente"
        echo '{"erro": "incidente falhou"}'
        return 1
    }
    
    # Compacta
    run tar -czf "${dir}.tar.gz" -C /tmp "$(basename "$dir")" 2>/dev/null || true
    log_info "Incidente compactado: ${dir}.tar.gz"
    
    echo "$json" | jq -c --arg arquivo "${dir}.tar.gz" '. + {arquivo_compactado: $arquivo}'
}

# 3. Analisa logs de erro
analisa_logs() {
    log_info "=== 3/6: Analisando logs ==="
    
    local all_results="[]"
    
    for arq in "${LOG_FILES[@]}"; do
        [[ -f "$arq" ]] || { log_aviso "Log não encontrado: $arq"; continue; }
        
        local json
        json=$(run sre-toolkit logs -f json -j "$arq" 2>/dev/null) || {
            log_aviso "Falha ao analisar $arq"
            continue
        }
        
        all_results=$(echo "$all_results" | jq -c --argjson a "$json" '. + $a.analises')
    done
    
    jq -n --argjson logs "$all_results" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{timestamp: $ts, logs_analisados: $logs}'
}

# 4. Verifica disco
verifica_disco() {
    log_info "=== 4/6: Verificando disco ==="
    
    local json
    json=$(run sre-toolkit disco --dir "$DISCO_DIR" --dias "$DISCO_DIAS" -j 2>/dev/null) || {
        log_erro "Falha ao verificar disco"
        echo '{"erro": "disco falhou"}'
        return 1
    }
    
    echo "$json"
}

# 5. Envia alerta se houver problemas
envia_alerta() {
    local health_json="$1" disco_json="$2" incidente_json="$3"
    
    local health_fail disco_antigos
    health_fail=$(echo "$health_json" | jq -r '.fail // 0')
    disco_antigos=$(echo "$disco_json" | jq -r '.arquivos_mais_antigos // 0')
    
    local tem_problema=0
    (( health_fail > 0 )) && tem_problema=1
    (( disco_antigos > 100 )) && tem_problema=1  # threshold arbitrário
    
    (( tem_problema == 0 )) && { log_info "Nenhum problema crítico, sem alerta"; echo "{}"; return 0; }
    
    [[ -z "$ALERT_WEBHOOK" ]] && { log_aviso "Webhook não configurado, pulando alerta"; echo "{}"; return 0; }
    
    log_info "=== 5/6: Enviando alerta ==="
    
    local titulo="🚨 Alerta SRE - Problemas Detectados"
    local msg="Healthcheck falhas: $health_fail | Arquivos antigos em disco: $disco_antigos"
    local severidade="warning"
    (( health_fail > 0 )) && severidade="critical"
    
    local payload
    payload=$(jq -n --arg t "$titulo" --arg m "$msg" --arg s "$severidade" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg hn "$(hostname)" \
        '{titulo:$t,mensagem:$m,severidade:$s,timestamp:$ts,hostname:$hn}')
    
    if (( DRY_RUN == 1 )); then
        log_info "[DRY-RUN] curl -sf --max-time 10 -H 'Content-Type: application/json' -d '$payload' $ALERT_WEBHOOK"
        echo '{"status": "dry-run", "payload": '"$payload"'}'
    else
        local resp
        resp=$(curl -sf --max-time 10 -H "Content-Type: application/json" -d "$payload" "$ALERT_WEBHOOK" 2>&1) || {
            log_erro "Falha ao enviar alerta: $resp"
            echo '{"erro": "alerta falhou"}'
            return 1
        }
        log_info "Alerta enviado com sucesso"
        echo '{"status": "enviado"}'
    fi
}

# 6. Gera relatório consolidado
gera_relatorio() {
    local health_json="$1" incidente_json="$2" logs_json="$3" disco_json="$4" alerta_json="$5"
    
    log_info "=== 6/6: Gerando relatório consolidado ==="
    
    local status_geral="ok"
    local health_fail
    health_fail=$(echo "$health_json" | jq -r '.fail // 0')
    (( health_fail > 0 )) && status_geral="falha"
    
    jq -n \
        --argjson health "$health_json" \
        --argjson incidente "$incidente_json" \
        --argjson logs "$logs_json" \
        --argjson disco "$disco_json" \
        --argjson alerta "$alerta_json" \
        --arg status "$status_geral" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{timestamp: $ts, status_geral: $status, healthcheck: $health, incidente: $incidente, logs: $logs, disco: $disco, alerta: $alerta}'
}

# --- Main ---
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) JSON_OUTPUT=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -c|--config) CONFIG_FILE="${2:-}"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) die "Opção desconhecida: $1" 2 ;;
        esac
    done

    carrega_config
    requer_comando sre-toolkit
    requer_comando jq
    requer_comando curl
    
    [[ -f "$SERVICOS_FILE" ]] || die "Arquivo de serviços não encontrado: $SERVICOS_FILE" 2
    [[ -f "$ENDPOINTS_FILE" ]] || die "Arquivo de endpoints não encontrado: $ENDPOINTS_FILE" 2
    
    log_info "início (json=$JSON_OUTPUT, dry-run=$DRY_RUN, verbose=$VERBOSE)"

    # Pipeline
    local health_json incidente_json logs_json disco_json alerta_json relatorio
    
    health_json=$(executa_healthcheck) || true
    incidente_json=$(executa_incidente "$health_json") || incidente_json='{}'
    logs_json=$(analisa_logs) || logs_json='{}'
    disco_json=$(verifica_disco) || disco_json='{}'
    alerta_json=$(envia_alerta "$health_json" "$disco_json" "$incidente_json") || alerta_json='{}'
    relatorio=$(gera_relatorio "$health_json" "$incidente_json" "$logs_json" "$disco_json" "$alerta_json")

    if (( JSON_OUTPUT == 1 )); then
        echo "$relatorio"
    else
        echo "$relatorio" | jq .
    fi

    local status
    status=$(echo "$relatorio" | jq -r '.status_geral')
    log_info "fim (status=$status)"
    [[ "$status" == "ok" ]] || exit 1
}

main "$@"
```

**Teste:**
```bash
# Preparar arquivos de configuração
cat > servicos.txt << 'EOF'
sshd
systemd-journald
EOF

cat > endpoints.txt << 'EOF'
https://httpbin.org/status/200
https://httpbin.org/status/500
EOF

# Criar logs de teste
bash 08-processamento-de-texto/exemplos/top-ips-nginx.sh /tmp/test-nginx.log 5
cat > /tmp/app.json.log << 'EOF'
{"timestamp":"2026-10-15T10:00:00Z","level":"ERROR","msg":"DB connection failed"}
{"timestamp":"2026-10-15T10:00:01Z","level":"INFO","msg":"Recovery"}
EOF

LOG_FILES=(/tmp/test-nginx.log /tmp/app.json.log)

# Executar (dry-run primeiro)
bash monitoramento-completo.sh -n -v
# Executar real
bash monitoramento-completo.sh -j > relatorio-final.json
jq . relatorio-final.json
```

**Saída esperada (JSON):**
```json
{
  "timestamp": "2026-10-15T14:50:00Z",
  "status_geral": "falha",
  "healthcheck": { "fail": 1, "verificacoes": [...] },
  "incidente": { "diretorio": "/tmp/incidente-...", "coleta_completa": 1 },
  "logs": { "logs_analisados": [...] },
  "disco": { "arquivos_mais_antigos": 0, ... },
  "alerta": { "status": "dry-run" }
}
```

Código de saída: `1` (pois healthcheck teve falha no endpoint 500).

---

## Critérios de Avaliação - Checklist

- [ ] Scripts usam `set -Eeuo pipefail`
- [ ] Variáveis locais em funções (`local`)
- [ ] Constantes com `readonly`
- [ ] `trap` para EXIT, INT, TERM, ERR
- [ ] Função `run()` para dry-run
- [ ] `log()` com níveis e output correto (stdout/stderr)
- [ ] `die()` para erros fatais com código
- [ ] `usage()` extraindo do cabeçalho
- [ ] Parse de argumentos robusto
- [ ] Saída JSON válida (`jq .` sem erro)
- [ ] Código de saída correto (0=sucesso, 1=falha, 2=uso, 3=prereq)
- [ ] Comentários explicativos
- [ ] `shellcheck` sem warnings
- [ ] `bash -n` sem erros de sintaxe