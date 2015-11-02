# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=1000
setopt appendhistory autocd extendedglob
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/alex/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

source "$HOME/.antigen/antigen.zsh"

antigen bundle git
antigen-use oh-my-zsh
antigen-bundle arialdomartini/oh-my-git
antigen theme arialdomartini/oh-my-git-themes oppa-lana-style
#antigen bundle pip
#antigen bundle rsync
#antigen bundle python
#antigen bundle node
#antigen bundle npm
#antigen bundle bundler
#antigen bundle zsh-users/zsh-completions src
#antigen bundle zsh-users/zsh-syntax-highlighting
#antigen bundle kennethreitz/autoenv
#antigen bundle command-not-found
#antigen bundle history
#antigen bundle tmux
#antigen bundle vundle
#antigen bundle sprunge
#antigen bundle fabric

#antigen-theme jreese
antigen-apply
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home/
export EDITOR=vim
export PATH=/usr/local/sbt/bin/:/usr/local/zinc/bin/:/usr/local/jdk/bin/:/usr/local/scala/bin/:$PATH:$HOME/repos/guake-colors-solarized:$HOME/bin/:/usr/local/idea/bin/:$HOME/repos/init-scripts/bin/
export CAGE=cage433.vm.bytemark.co.uk
export CARY=178.62.56.14
alias cary='ssh $CARY'
alias cage='ssh alex@$CAGE'
alias gs='git status'
alias zinc='zinc -Dzinc.analysis.cache.limit=50'
alias gitp='git --no-pager'
CASE_SENSITIVE=true
export MAKER_SONATYPE_CREDENTIALS=cage433:zoltan
export MAKER_GPG_PASS_PHRASE=smal3Pices
bindkey -v
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^r' history-incremental-search-backward
