#!/usr/bin/env bash
#
# cron-para-systemd.sh - Exemplos de migração de cron para systemd timers
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-14
#
# Uso:
#   cron-para-systemd.sh
#
# Códigos de saída:
#   0  Sucesso
#
# Exemplos:
#   ./cron-para-systemd.sh
#
# Demonstra:
#   - Exemplos de cron tradicional
#   - Equivalentes systemd timers com configurações completas
#   - Comparação de vantagens entre cron e systemd timers
#   - Quando usar cada abordagem
#   - Boas práticas de systemd timers
#
# =============================================================================

# --- Modo Estrito ------------------------------------------------------------
set -Eeuo pipefail

# --- Configuração ------------------------------------------------------------
readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

DRY_RUN=0
VERBOSE=0

log() {
    local nivel="$1"
    shift
    local ts
    ts=$(date '+%F %T')
    local msg="${ts} [${nivel}] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$msg" >> "$LOG_FILE"
    [[ "$nivel" != "DEBUG" ]] && printf '%s\n' "$msg"
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@" >&2; }
log_erro()  { log ERRO  "$@" >&2; }

die() {
    local msg="$1"
    local codigo="${2:-1}"
    log_erro "$msg"
    exit "$codigo"
}

cleanup() {
    local codigo=$?
    if [[ $codigo -eq 0 ]]; then
        log_info "terminou com sucesso"
    else
        log_erro "terminou com falha (código ${codigo})"
    fi
}
trap cleanup EXIT
trap 'die "interrompido pelo usuário" 130' INT
trap 'die "recebeu sinal de término" 143' TERM
trap 'log_erro "erro na linha ${LINENO}: ${BASH_COMMAND}"' ERR

requer_comando() {
    command -v "$1" > /dev/null 2>&1 || die "comando obrigatório não encontrado: $1" 3
}

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] $*"
        return 0
    else
        log_debug "executando: $*"
        "$@"
    fi
}

usage() {
    sed -n '3,/^# ====/p' "$0" | head -n -1 | sed 's/^# \{0,1\}//'
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            --) shift; break ;;
            -*) die "opção desconhecida: $1" 2 ;;
            *) break ;;
        esac
    done

    log_info "início (dry-run=$DRY_RUN, verbose=$VERBOSE)"

    echo "=========================================="
    echo "MIGRAÇÃO CRON -> SYSTEMD TIMERS"
    echo "=========================================="
    echo

    echo "--- 1. CRON TRADICIONAL (/etc/crontab ou crontab -e) ---"
    cat << 'EOF'
# Formato: min hora dia-mes mes dia-semana comando
# Exemplo: backup diário às 02:30
30 2 * * * root /usr/local/sbin/backup-rotativo.sh -r 7 /dados /backup >> /var/log/backup.log 2>&1

# Exemplo: healthcheck a cada 15 minutos
*/15 * * * * nagios /usr/local/bin/healthcheck.sh >> /var/log/healthcheck.log 2>&1

# Exemplo: limpeza semanal domingos 03:00
0 3 * * 0 root /usr/local/sbin/limpa-logs.sh -d 30 /var/log/app >> /var/log/limpeza.log 2>&1

# Exemplo: no reboot
@reboot root /usr/local/sbin/startup-script.sh >> /var/log/startup.log 2>&1
EOF
    echo

    echo "--- 2. EQUIVALENTES SYSTEMD TIMERS ---"
    echo
    echo "A) backup-diario.timer (diário 02:30 com jitter e persistência)"
    cat << 'EOF'
[Unit]
Description=Backup diário
Requires=backup-diario.service

[Timer]
OnCalendar=daily 02:30
Persistent=true
RandomizedDelaySec=15min
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF
    echo
    echo "B) healthcheck.timer (a cada 15 min)"
    cat << 'EOF'
[Timer]
OnCalendar=*:0/15
Persistent=true
RandomizedDelaySec=2min
AccuracySec=1min
EOF
    echo
    echo "C) limpeza-semanal.timer (domingos 03:00)"
    cat << 'EOF'
[Timer]
OnCalendar=Sun 03:00
Persistent=true
RandomizedDelaySec=30min
EOF
    echo
    echo "D) startup-script.service (no boot, sem timer)"
    cat << 'EOF'
[Unit]
Description=Script de inicialização
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/startup-script.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
# Habilita com: systemctl enable startup-script.service
# (Não precisa de .timer para @reboot)
EOF
    echo

    echo "--- 3. VANTAGENS SYSTEMD TIMERS vs CRON ---"
    cat << 'EOF'
| Recurso                    | Cron                    | Systemd Timer              |
|----------------------------|-------------------------|----------------------------|
| Persistência (rodar se off)| Não (anacron separado)  | Sim (Persistent=true)      |
| Jitter (aleatoriedade)     | Manual (sleep $RANDOM)  | Nativo (RandomizedDelaySec)|
| Logs centralizados         | Arquivos dispersos      | journalctl -u servico      |
| Dependências               | Não                     | Sim (After, Requires, etc) |
| Sandbox/Segurança          | Não                     | Sim (PrivateTmp, Protect*) |
| Timeout                    | Não                     | Sim (TimeoutStartSec)      |
| Status/Monitoramento       | crontab -l / logs       | systemctl status / list-timers |
| Execução imediata          | Manual                  | systemctl start servico    |
| Paralelo/Serial            | Sempre paralelo         | Controlável                |
| Recursos (CPU/Mem)         | Não                     | Sim (MemoryLimit, CPUQuota)|
EOF
    echo

    echo "--- 4. QUANDO USAR CADA UM ---"
    cat << 'EOF'
USE CRON quando:
- Scripts simples, usuário único, sem dependências
- Ambientes sem systemd (containers minimalistas, BSD)
- Agendamento muito simples (ex: * * * * *)
- Precisa rodar como usuário não-root sem sudo

USE SYSTEMD TIMERS quando:
- Serviços de produção (SRE/Infra)
- Precisa de logs centralizados (journalctl)
- Tem dependências (rede, outro serviço, montagem)
- Precisa de segurança (sandbox, capabilities, namespaces)
- Quer monitoramento nativo (systemctl status, Prometheus node_exporter)
- Precisa de persistência (rodar no boot se perdeu horário)
- Quer jitter nativo para evitar thundering herd
EOF
    echo

    echo "--- 5. BOAS PRÁTICAS ---"
    cat << 'EOF'
1. SEMPRE use Type=oneshot para scripts que terminam
2. Use User/Group dedicado (não root)
3. Configure sandbox: PrivateTmp, ProtectSystem, NoNewPrivileges
4. Defina TimeoutStartSec (evita processos travados)
5. Use StandardOutput=journal + StandardError=journal
6. Use Persistent=true para timers críticos
7. Use RandomizedDelaySec em frotas (evita picos)
8. Teste com: systemctl start servico.service
9. Monitore com: systemctl list-timers --all
10. Debug com: journalctl -u servico -f
EOF

    log_info "fim"
}

main "$@"