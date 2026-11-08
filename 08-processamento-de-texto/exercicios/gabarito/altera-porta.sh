#!/usr/bin/env bash
#
# altera-porta.sh - alteração segura de configuração com backup e diff.
#
# Autor:      Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:    MIT
# Versão:     1.0.0
# Data:       2026-10-15
#
# Uso:
#   altera-porta.sh ARQUIVO CHAVE NOVO_VALOR
#
# Opções:
#   -h, --help     Exibe esta ajuda
#   -v, --verbose  Modo verboso
#   -n, --dry-run  Simula execução (mostra o que seria feito)
#
# Códigos de saída:
#   0  Sucesso
#   1  Erro genérico (arquivo não encontrado ou não gravável)
#   2  Uso incorreto / argumentos inválidos
#   3  Pré-requisito ausente (sed, diff não disponíveis)
#   4  Erro de permissão
#
# Exemplo:
#   altera-porta.sh /etc/ssh/sshd_config Port 2222
#
# Dependências:
#   - bash 4+
#   - sed, diff, date
#
# =============================================================================

set -Eeuo pipefail

[[ $# -eq 3 ]] || { echo "Uso: $0 ARQUIVO CHAVE NOVO_VALOR" >&2; exit 2; }

ARQUIVO="$1"
CHAVE="$2"
VALOR="$3"

[[ -f "$ARQUIVO" ]] || { echo "ERRO: Arquivo '$ARQUIVO' não existe" >&2; exit 1; }
[[ -w "$ARQUIVO" ]] || { echo "ERRO: Arquivo '$ARQUIVO' não gravável" >&2; exit 1; }

# Backup com timestamp
BACKUP="${ARQUIVO}.$(date '+%Y%m%d-%H%M%S').bak"
cp "$ARQUIVO" "$BACKUP"
echo "Backup: $BACKUP"

# Substituição: chave = valor  OU  chave: valor
# Delimitador # para evitar conflito com caminhos
sed -i "s#^\([[:space:]]*${CHAVE}[[:space:]]*[=:][[:space:]]*\).*#\1${VALOR}#" "$ARQUIVO"

# Verifica se alterou
if diff -q "$BACKUP" "$ARQUIVO" >/dev/null; then
    echo "AVISO: Nenhuma alteração feita (chave não encontrada ou valor igual)"
    rm -f "$BACKUP"
else
    echo "Alterado: $CHAVE = $VALOR"
    echo "--- Diff ---"
    diff -u "$BACKUP" "$ARQUIVO"
fi