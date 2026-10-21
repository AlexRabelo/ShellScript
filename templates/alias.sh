#!/usr/bin/env bash
#
# alias.sh - Aliases e configurações úteis para shell
#
# Uso: source alias.sh  (ou adicione ao ~/.bashrc)
#
# Licença: MIT

# Define new aliases
alias tm='clear && tail -f /var/log/messages'
alias tmm='clear && tail -f /var/log/maillog'
alias tms='clear && tail -f /var/log/secure'

# Configurações personalizadas
# Opções personalizadas do history
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoredups
HISTIGNORE="pwd:ls:ll:ls -ltr:"
HISTTIMEFORMAT="%d-%b-%Y %T -> "
export HISTTIMEFORMAT HISTSIZE HISTFILESIZE HISTCONTROL HISTIGNORE