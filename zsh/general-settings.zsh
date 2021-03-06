export EDITOR=vim
export CAGE="cage433.vm.bytemark.co.uk"
export JQ="johnquays.default.amcguire.uk0.bigv.io"
alias cage='ssh $CAGE'
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
alias gitp='git --no-pager'
alias thoozaho-git='git config user.name thoozaho && git config user.email thoozaho@gmail.com'
alias cage433-git='git config user.name cage433 && git config user.email cage433@gmail.com'
alias gs='git status'
alias tmux='TERM=xterm-256color tmux'
alias tmuxc='TERM=xterm-256color tmux -f ~/.tmux.colemak.conf'
alias long-lines='ack-grep --type=scala -l ".{121,}"'                                                                                                                                
alias ta='export TERM=screen-256color && tmux attach -d'
alias ssh='TERM=xterm ssh'
alias vimc="vim -S $HOME/repos/init-scripts/vim/colemak.vim"
rightDiff(){
  file=$1
  diff <(sed -n '/^||||||/,/=======/p' $file) <(sed -n '/=======/,/>>>>>>>/p' $file)
}
leftDiff(){
  file=$1
  diff <(sed -n '/^<<<<<</,/||||||/p' $file) <(sed -n '/|||||||/,/=======/p' $file)
}
outerDiff(){
  file=$1
  diff <(sed -n '/^<<<<<</,/||||||/p' $file) <(sed -n '/=======/,/>>>>>>/p' $file)
}
