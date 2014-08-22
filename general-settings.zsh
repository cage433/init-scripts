export EDITOR=vim
export CAGE="alex@cage433.vm.bytemark.co.uk"
setxkbmap -option "ctrl:nocaps" > /dev/null 2>&1
export PATH=$HOME/repos/init-scripts/bin/:$PATH
export SCALA_HOME=/usr/local/scala-2.10.2
bindkey -v
export KEYTIMEOUT=1
# Use vim cli mode
bindkey '^P' up-history
bindkey '^N' down-history

# backspace and ^h working even after
# returning from command mode
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# ctrl-w removed word backwards
bindkey '^w' backward-kill-word

# ctrl-r starts searching history backward
bindkey '^r' history-incremental-search-backward
alias kill-tmux='tmux ls | awk "{print $1}" | sed s/:// | xargs -I{} tmux kill-session -t {}'
alias s9='export SCALA_HOME=/usr/local/scala-2.9.3/'
alias s10='export SCALA_HOME=/usr/local/scala-2.10.2/'
export SCALA_HOME=/usr/local/scala-2.9.3/