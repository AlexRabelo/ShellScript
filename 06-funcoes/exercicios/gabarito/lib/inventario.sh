#!/usr/bin/env bash
#
# lib/inventario.sh - funções para manipular inventário de servidores.
#
# Uso: source lib/inventario.sh
#      declare -A MEU_INVENTARIO
#      carrega_inventario "hosts.csv" MEU_INVENTARIO

carrega_inventario() {
    local arquivo="$1"
    local -n arr="$2"  # nameref para array associativo (Bash 4.3+)

    [[ -f "$arquivo" ]] || { echo "ERRO: Arquivo '$arquivo' não encontrado" >&2; return 1; }

    while IFS=',' read -r host ip ambiente role; do
        [[ "$host" == "HOST" || "$host" == "NOME" ]] && continue
        host=$(echo "$host" | xargs)
        ip=$(echo "$ip" | xargs)
        ambiente=$(echo "$ambiente" | xargs)
        role=$(echo "$role" | xargs)
        arr["$host"]="${ip},${ambiente},${role}"
    done < "$arquivo"
}

filtra_por_ambiente() {
    local -n arr="$1"
    local ambiente="$2"

    for host in "${!arr[@]}"; do
        IFS=',' read -r ip amb role <<< "${arr[$host]}"
        if [[ "$amb" == "$ambiente" ]]; then
            echo "$host,$ip,$amb,$role"
        fi
    done
}

contagem_por_ambiente() {
    local -n arr="$1"
    declare -A contagem

    for host in "${!arr[@]}"; do
        IFS=',' read -r ip amb role <<< "${arr[$host]}"
        (( contagem["$amb"]++ ))
    done

    for amb in "${!contagem[@]}"; do
        echo "$amb: ${contagem[$amb]}"
    done
}

# Teste se executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    declare -A INV
    carrega_inventario "/tmp/inventario.csv" INV 2>/dev/null || {
        # Cria arquivo de teste
        cat > /tmp/inventario.csv << 'EOF'
HOST,IP,AMBIENTE,ROLE
web01,10.0.1.10,producao,web
web02,10.0.1.11,producao,web
db01,10.0.2.10,producao,db
cache01,10.0.3.10,homologacao,cache
EOF
        carrega_inventario "/tmp/inventario.csv" INV
    }

    echo "=== Produção ==="
    filtra_por_ambiente INV producao

    echo
    echo "=== Contagem ==="
    contagem_por_ambiente INV
fi