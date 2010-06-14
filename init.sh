if [ ! -e $HOME/.vim ]; then
	echo "Creating link to .vim "
	ln -s $HOME/github/alex-init-scripts/dot-vim $HOME/.vim
fi
if [ ! -e $HOME/.vimrc ]; then
	echo "Creating link to .vimrc "
	ln -s $HOME/github/alex-init-scripts/dot-vimrc $HOME/.vimrc
fi
