#!/usr/bin/env bash
#
# gera-dashboard.sh - Gera dashboard HTML estático de status dos healthchecks
# Lê JSONs de healthchecks e gera index.html.

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${LOG_FILE:-/tmp/${SCRIPT_NAME%.sh}.log}"

INPUT_DIR="/var/lib/healthchecks"
OUTPUT_DIR="/var/www/status"
TITULO="Status dos Serviços"
REFRESH=30
DRY_RUN=0

log() {
    local n="$1"
    shift
    local m
    m="$(date '+%F %T') [$n] ${SCRIPT_NAME}[$$]: $*"
    printf '%s\n' "$m" >> "$LOG_FILE" 2>/dev/null || true
    case "$n" in
        ERRO|AVISO) printf '%s\n' "$m" >&2 ;;
        *) printf '%s\n' "$m" ;;
    esac
}

log_info()  { log INFO  "$@"; }
log_aviso() { log AVISO "$@"; }
log_erro()  { log ERRO  "$@"; }

die() { local c="${2:-1}"; log_erro "$1"; exit "$c"; }

cleanup() { local c=$?; [[ $c -eq 0 ]] || log_erro "falha ($c)"; }
trap cleanup EXIT
trap 'die "interrompido" 130' INT
trap 'die "terminado" 143' TERM

requer_comando() { command -v "$1" >/dev/null 2>&1 || die "comando: $1" 3; }
usage() { sed -n '3,24p' "$0" | sed 's/^# \{0,1\}//'; }

html_escape() { sed "s/&/\\&/g; s/</\\</g; s/>/\\>/g; s/\"/\\\\\"/g; s/'/\\'/g"; }

imprime_html() {
    local total_checks=0 total_ok=0 total_fail=0
    local rows=""

    local json_files=("$INPUT_DIR"/*.json)
    [[ -e "${json_files[0]}" ]] || { log_aviso "nenhum JSON em $INPUT_DIR"; return 1; }

    for f in "${json_files[@]}"; do
        local service_name ts total ok falhas status_class status_text
        service_name=$(basename "$f" .json)
        ts=$(jq -r '.timestamp // ""' "$f" 2>/dev/null || echo "")
        total=$(jq -r '.total // 0' "$f" 2>/dev/null || echo 0)
        ok=$(jq -r '.ok // 0' "$f" 2>/dev/null || echo 0)
        falhas=$(jq -r '.falhas // 0' "$f" 2>/dev/null || echo 0)

        total_checks=$(( total_checks + total ))
        total_ok=$(( total_ok + ok ))
        total_fail=$(( total_fail + falhas ))

        status_class="ok"; status_text="OK"
        [[ $falhas -gt 0 ]] && { status_class="fail"; status_text="DOWN"; }
        [[ $falhas -eq 0 && $ok -lt $total ]] && { status_class="degraded"; status_text="DEGRADED"; }

        local details=""
        local checks
        checks=$(jq -c '.verificacoes[]? // empty' "$f" 2>/dev/null)
        if [[ -n "$checks" ]]; then
            details=$(echo "$checks" | while IFS= read -r c; do
                local nome status duracao erro
                nome=$(echo "$c" | jq -r '.nome // .url // "check"')
                status=$(echo "$c" | jq -r '.status // "unknown"')
                duracao=$(echo "$c" | jq -r '.duracao_ms // 0')
                erro=$(echo "$c" | jq -r '.erro // ""')
                local detail_class="ok"
                [[ "$status" == "fail" ]] && detail_class="fail"
                local n s e
                n=$(html_escape <<< "$nome")
                s=$(html_escape <<< "$status")
                e=$(html_escape <<< "$erro")
                printf '<div class="detail %s"><span class="name">%s:</span> <span class="status">%s</span> <span class="latency">%sms</span> <span class="error">%s</span></div>' "$detail_class" "$n" "$s" "$duracao" "$e"
            done)
        fi

        rows+=$(cat <<ROWEOF
        <tr class="$status_class">
            <td><strong>$(html_escape <<< "$service_name")</strong></td>
            <td><span class="badge $status_class">$status_text</span></td>
            <td>$ts</td>
            <td>${ok}/${total}</td>
            <td><details><summary>Ver detalhes</summary><div class="details">$details</div></details></td>
        </tr>
ROWEOF
)
    done

    badge_class="ok"
    [[ $total_fail -gt 0 ]] && badge_class="fail"
    [[ $total_fail -eq 0 && $total_ok -lt $total_checks ]] && badge_class="degraded"
    local degraded
    degraded=$(( total_checks - total_ok - total_fail ))
    local timestamp
    timestamp=$(date '+%d/%m/%Y %H:%M:%S')
    local refresh_meta=""
    [[ $REFRESH -gt 0 ]] && refresh_meta="<meta http-equiv=\"refresh\" content=\"$REFRESH\">"

    cat <<HTMLEOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$(html_escape <<< "$TITULO")</title>
    $refresh_meta
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); overflow: hidden; }
        header { background: #2c3e50; color: white; padding: 20px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; }
        h1 { font-size: 1.5rem; font-weight: 600; }
        .badge { padding: 4px 12px; border-radius: 20px; font-size: 0.85rem; font-weight: 600; text-transform: uppercase; }
        .badge.ok { background: #27ae60; color: white; }
        .badge.degraded { background: #f39c12; color: white; }
        .badge.fail { background: #e74c3c; color: white; }
        .summary { display: flex; gap: 20px; padding: 20px; background: #f8f9fa; border-bottom: 1px solid #eee; flex-wrap: wrap; }
        .summary-item { display: flex; flex-direction: column; }
        .summary-label { font-size: 0.75rem; color: #666; text-transform: uppercase; letter-spacing: 0.5px; }
        .summary-value { font-size: 1.5rem; font-weight: 700; }
        .summary-value.ok { color: #27ae60; }
        .summary-value.degraded { color: #f39c12; }
        .summary-value.fail { color: #e74c3c; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #f8f9fa; font-weight: 600; color: #333; white-space: nowrap; }
        tr:hover { background: #fafafa; }
        tr.ok { border-left: 4px solid #27ae60; }
        tr.degraded { border-left: 4px solid #f39c12; }
        tr.fail { border-left: 4px solid #e74c3c; }
        .details { margin-top: 8px; padding: 8px; background: #f8f9fa; border-radius: 4px; font-size: 0.85rem; }
        .detail { padding: 4px 0; display: flex; gap: 8px; }
        .detail.ok { color: #27ae60; }
        .detail.fail { color: #e74c3c; }
        .detail .name { font-weight: 500; min-width: 120px; }
        .detail .status { font-weight: 600; text-transform: uppercase; min-width: 60px; }
        .detail .latency { color: #666; font-family: monospace; }
        .detail .error { color: #e74c3c; font-style: italic; }
        details summary { cursor: pointer; color: #3498db; font-weight: 500; }
        details summary:hover { text-decoration: underline; }
        .filter { padding: 12px 20px; background: #f8f9fa; border-bottom: 1px solid #eee; display: flex; gap: 10px; flex-wrap: wrap; }
        .filter button { padding: 6px 12px; border: 1px solid #ddd; background: white; border-radius: 4px; cursor: pointer; transition: all 0.2s; }
        .filter button.active { background: #2c3e50; color: white; border-color: #2c3e50; }
        .filter button:hover:not(.active) { background: #f0f0f0; }
        footer { padding: 16px 20px; text-align: center; color: #666; font-size: 0.85rem; border-top: 1px solid #eee; }
        .hidden { display: none !important; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>$(html_escape <<< "$TITULO")</h1>
            <div class="badge $badge_class">${total_ok} OK • ${total_fail} DOWN • $(( total_checks - total_ok - total_fail )) DEGRADED</div>
        </header>

        <div class="summary">
            <div class="summary-item"><span class="summary-label">Total Checks</span><span class="summary-value">$total_checks</span></div>
            <div class="summary-item"><span class="summary-label">OK</span><span class="summary-value ok">$total_ok</span></div>
            <div class="summary-item"><span class="summary-label">DOWN</span><span class="summary-value fail">$total_fail</span></div>
            <div class="summary-item"><span class="summary-label">DEGRADED</span><span class="summary-value degraded">$(( total_checks - total_ok - total_fail ))</span></div>
            <div class="summary-item"><span class="summary-label">Última Atualização</span><span class="summary-value">$timestamp</span></div>
        </div>

        <div class="filter">
            <button class="active" data-filter="all">Todos</button>
            <button data-filter="ok">OK</button>
            <button data-filter="degraded">DEGRADED</button>
            <button data-filter="fail">DOWN</button>
        </div>

        <table id="services-table">
            <thead>
                <tr>
                    <th>Serviço</th>
                    <th>Status</th>
                    <th>Última Verificação</th>
                    <th>Checks</th>
                    <th>Ações</th>
                </tr>
            </thead>
            <tbody>
                $rows
            </tbody>
        </table>

        <footer>
            Gerado por <code>$SCRIPT_NAME</code> em $timestamp | Host: $(hostname) | Auto-refresh: ${REFRESH}s
        </footer>
    </div>

    <script>
        document.querySelectorAll('.filter button').forEach(btn => {
            btn.addEventListener('click', function() {
                document.querySelectorAll('.filter button').forEach(b => b.classList.remove('active'));
                this.classList.add('active');
                const filter = this.dataset.filter;
                document.querySelectorAll('#services-table tbody tr').forEach(row => {
                    if (filter === 'all' || row.classList.contains(filter)) {
                        row.classList.remove('hidden');
                    } else {
                        row.classList.add('hidden');
                    }
                });
            });
        });

        if ($REFRESH > 0) {
            let countdown = $REFRESH;
            const badge = document.querySelector('header .badge');
            const originalText = badge.textContent;
            setInterval(() => {
                countdown--;
                badge.textContent = originalText + ' | Refresh em ' + countdown + 's';
                if (countdown <= 0) countdown = $REFRESH;
            }, 1000);
        }
    </script>
</body>
</html>
HTMLEOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--input) INPUT_DIR="${2:-}"; shift 2 ;;
            -o|--output) OUTPUT_DIR="${2:-}"; shift 2 ;;
            -t|--titulo) TITULO="${2:-}"; shift 2 ;;
            -r|--refresh) REFRESH="${2:-}"; shift 2 ;;
            --dry-run) DRY_RUN=1; shift ;;
            -h|--help) usage; exit 0 ;;
            -*) die "opção: $1" 2 ;;
            *) die "argumento: $1" 2 ;;
        esac
    done

    [[ -d "$INPUT_DIR" ]] || die "diretório não existe: $INPUT_DIR" 1
    [[ "$REFRESH" =~ ^[0-9]+$ ]] || die "refresh inválido: $REFRESH" 2

    log_info "gerando dashboard (input=$INPUT_DIR, output=$OUTPUT_DIR, refresh=$REFRESH)"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        imprime_html
    else
        mkdir -p "$OUTPUT_DIR" 2>/dev/null || die "não pode criar $OUTPUT_DIR"
        [[ -w "$OUTPUT_DIR" ]] || die "sem permissão em $OUTPUT_DIR"
        imprime_html > "$OUTPUT_DIR/index.html"
        log_info "dashboard gerado em $OUTPUT_DIR/index.html"
    fi
}

main "$@"