# Makefile para sre-toolkit

.PHONY: install uninstall test lint help

PREFIX?=/usr/local
BIN_DIR=$(PREFIX)/sbin
LIB_DIR=$(PREFIX)/sre-toolkit/lib
COMANDOS_DIR=$(PREFIX)/sre-toolkit/comandos
CONFIG_DIR=$(PREFIX)/etc/sre-toolkit

VERSION=1.0.0

help:
	@echo "sre-toolkit Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make install     - Instala o toolkit"
	@echo "  make uninstall   - Remove o toolkit"
	@echo "  make test        - Executa testes básicos"
	@echo "  make lint        - Verifica shellcheck"
	@echo "  make help        - Esta ajuda"
	@echo ""

install:
	@echo "Instalando sre-toolkit v$(VERSION)..."
	@mkdir -p $(BIN_DIR) $(LIB_DIR) $(COMANDOS_DIR) $(CONFIG_DIR)
	@cp bin/sre-toolkit $(BIN_DIR)/
	@cp -r lib/* $(LIB_DIR)/
	@cp -r comandos/* $(COMANDOS_DIR)/
	@cp config/sre-toolkit.conf.example $(CONFIG_DIR)/sre-toolkit.conf
	@chmod +x $(BIN_DIR)/sre-toolkit
	@chmod +x $(LIB_DIR)/*.sh
	@chmod +x $(COMANDOS_DIR)/*.sh
	@echo "Instalação concluída!"
	@echo "Lembre-se de configurar $(CONFIG_DIR)/sre-toolkit.conf"

uninstall:
	@echo "Removendo sre-toolkit..."
	@rm -f $(BIN_DIR)/sre-toolkit
	@rm -rf $(LIB_DIR)
	@rm -rf $(COMANDOS_DIR)
	@rm -f $(CONFIG_DIR)/sre-toolkit.conf
	@echo "Remoção concluída."

test:
	@echo "Executando testes básicos..."
	@bin/sre-toolkit --help >/dev/null && echo "✓ help ok"
	@bin/sre-toolkit saude -h >/dev/null && echo "✓ saude help ok"
	@bin/sre-toolkit disco -h >/dev/null && echo "✓ disco help ok"
	@bin/sre-toolkit backup -h >/dev/null && echo "✓ backup help ok"
	@bin/sre-toolkit health -h >/dev/null && echo "✓ health help ok"
	@bin/sre-toolkit logs -h >/dev/null && echo "✓ logs help ok"
	@bin/sre-toolkit aws -h >/dev/null && echo "✓ aws help ok"
	@bin/sre-toolkit incidente -h >/dev/null && echo "✓ incidente help ok"
	@echo "Testes concluídos!"

lint:
	@echo "Executando shellcheck..."
	@shellcheck bin/sre-toolkit lib/*.sh comandos/*.sh 2>/dev/null || echo "shellcheck não instalado ou avisos encontrados"
	@echo "Lint concluído."

dist:
	@echo "Criando distribuição..."
	@mkdir -p sre-toolkit-$(VERSION)
	@cp -r bin lib comandos config README.md LICENSE sre-toolkit-$(VERSION)/
	@tar -czf sre-toolkit-$(VERSION).tar.gz sre-toolkit-$(VERSION)/
	@rm -rf sre-toolkit-$(VERSION)
	@echo "Distribuição criada: sre-toolkit-$(VERSION).tar.gz"

.PHONY: install uninstall test lint help dist