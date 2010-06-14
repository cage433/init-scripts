if [ ! -e $HOME/.vim ]; then
	echo "Creating link to .vim "
	ln -s $HOME/github/alex-init-scripts/vim/dot-vim $HOME/.vim
fi
if [ ! -e $HOME/.vimrc ]; then
	echo "Creating link to .vimrc "
	ln -s $HOME/github/alex-init-scripts/vim/dot-vimrc $HOME/.vimrc
fi
if [ ! -e $HOME/.ctags ]; then
	echo "Creating link to .ctags "
	ln -s $HOME/github/alex-init-scripts/dot-ctags $HOME/.ctags
fi
