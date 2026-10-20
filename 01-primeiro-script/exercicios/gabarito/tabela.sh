#!/usr/bin/env bash
#
# tabela.sh - exibe uma tabela de servidores alinhada em colunas.

printf "%-10s %-10s %s\n" "SERVIDOR" "FUNCAO" "STATUS"
printf "%-10s %-10s %s\n" "web01" "frontend" "ativo"
printf "%-10s %-10s %s\n" "db01" "banco" "ativo"
printf "%-10s %-10s %s\n" "bkp01" "backup" "parado"
