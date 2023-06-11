# Define new aliases
alias tm='clear & tail -f /var/log/messages'
alias tmm='clear & tail -f /var/log/maillog'
alias tms='clear & tail -f /var/log/secure'

# Configuracoes personalizadas
# Opcoes personalizadas do history
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoredups
HISTIGNORE="pwd:ls:ll:ls -ltr:"
export readonly HISTTIMEFORMAT="%d-%b-%Y %T -> "
export readonly HISTSIZE HISTFILESIZE HISTCONTROL HISTIGNORE

