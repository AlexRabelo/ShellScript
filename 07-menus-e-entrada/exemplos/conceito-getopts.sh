#!/usr/bin/env bash
# conceito-getopts.sh — getopts + flags longas (versão didática)

# Converte flags longas para curtas
args=()
for arg in "$@"; do
    case "$arg" in
        --help) args+=("-h") ;;
        --verbose) args+=("-v") ;;
        --dry-run) args+=("-n") ;;
        --file=*) args+=("-f" "${arg#*=}") ;;
        --output=*) args+=("-o" "${arg#*=}") ;;
        *) args+=("$arg") ;;
    esac
done
set -- "${args[@]}"

VERBOSE=0
DRY_RUN=0
ARQUIVO=""
OUTPUT=""

while getopts "hvnf:o:" opt; do
    case "$opt" in
        h)
            echo "Uso: $0 [-v] [-n] [-f ARQUIVO] [-o OUTPUT] [ARGS...]"
            echo "  -v, --verbose   Verboso"
            echo "  -n, --dry-run   Simula"
            echo "  -f, --file      Arquivo de entrada"
            echo "  -o, --output    Arquivo de saída"
            exit 0
            ;;
        v) VERBOSE=1 ;;
        n) DRY_RUN=1 ;;
        f) ARQUIVO="$OPTARG" ;;
        o) OUTPUT="$OPTARG" ;;
        *) echo "Opção inválida: -$OPTARG" >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

echo "VERBOSE=$VERBOSE"
echo "DRY_RUN=$DRY_RUN"
echo "ARQUIVO=$ARQUIVO"
echo "OUTPUT=$OUTPUT"
echo "Args restantes: $*"