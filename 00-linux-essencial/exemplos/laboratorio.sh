#!/usr/bin/env bash
#
# laboratorio.sh - Comandos essenciais do Linux (Módulo 00)
#
# Autor:       Alex Rabelo
# Repositório: https://github.com/AlexRabelo/ShellScript
# Licença:     MIT
# Versão:      1.0.0
#
# Uso:
#   bash laboratorio.sh
#
# Este script executa exemplos básicos do módulo.
# Leia os comentários e observe o resultado de cada comando.
#

# Diretório de laboratório. Os exemplos não alteram arquivos do projeto.
mkdir -p /tmp/lab-linux/logs /tmp/lab-linux/backup
cd /tmp/lab-linux || exit 1

echo "=== 1. Navegação ==="
pwd
ls -la

echo
echo "=== 2. Criando e lendo arquivo ==="
touch notas.txt
echo "primeira linha" > notas.txt
echo "segunda linha" >> notas.txt
echo "terceira linha" >> notas.txt
cat notas.txt

echo
echo "=== 3. Procurando texto ==="
echo "INFO servico iniciado" > logs/app.log
echo "ERRO falha ao conectar" >> logs/app.log
echo "INFO servico finalizado" >> logs/app.log
grep "ERRO" logs/app.log

echo
echo "=== 4. Pipe ==="
# O pipe envia a saída do grep para o contador.
# shellcheck disable=SC2126
grep "INFO" logs/app.log | wc -l

echo
echo "=== 5. Copiando e movendo ==="
cp notas.txt backup/notas.bak
mv notas.txt anotacoes.txt
ls -l . backup

echo
echo "=== 6. Permissões ==="
touch executavel.sh
ls -l executavel.sh
chmod 755 executavel.sh
ls -l executavel.sh

echo
echo "=== 7. Redirecionamento de erro ==="
ls /pasta-que-nao-existe 2> logs/erros.txt
echo "Conteúdo de logs/erros.txt:"
cat logs/erros.txt

echo
echo "=== 8. Encontrando arquivos ==="
find /tmp/lab-linux -name "*.txt"

echo
echo "Laboratório concluído. Arquivos criados em /tmp/lab-linux."