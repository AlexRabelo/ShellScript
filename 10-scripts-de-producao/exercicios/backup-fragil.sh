#!/usr/bin/env bash
# backup-fragil.sh - BACKUP FRÁGIL (NÃO USE EM PRODUÇÃO)

DIR_ORIGEM=$1
DIR_DESTINO=$2

tar -czf $DIR_DESTINO/backup-$(date +%F).tar.gz $DIR_ORIGEM
echo "Backup concluído em $DIR_DESTINO/backup-$(date +%F).tar.gz"