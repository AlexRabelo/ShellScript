#!/usr/bin/env bash
# script-com-avisos.sh - Script com avisos do ShellCheck para corrigir

arquivos=$(ls /var/log/*.log)
for arq in $arquivos; do
  linhas=$(cat $arq | wc -l)
  echo "Arquivo: $arq, Linhas: $linhas"
done

if [ $linhas -gt 1000 ]; then
  echo "Arquivo grande detectado"
fi

funcao() {
  local var=$1
  echo $var
}

funcao "teste"