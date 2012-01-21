if [ ! -e $HOME/.vim ]; then
	echo "Creating link to .vim "
	ln -s $PWD/vim/dot-vim $HOME/.vim
fi
if [ ! -e $HOME/.vimrc ]; then
	echo "Creating link to .vimrc "
	ln -s $PWD/vim/dot-vimrc $HOME/.vimrc
fi
if [ ! -e $HOME/.ctags ]; then
	echo "Creating link to .ctags "
	ln -s $PWD/dot-ctags $HOME/.ctags
fi
if [ ! -e $HOME/.tmux.conf ]; then
	echo "Creating link to .tmux.conf"
	ln -s $PWD/dot-tmux-dot-conf $HOME/.tmux.conf
fi
