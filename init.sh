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
if [ ! -e $HOME/.ackrc ]; then
	echo "Creating link to .ackrc"
	ln -s $PWD/dot-ackrc $HOME/.ackrc
fi
if [ ! -e $HOME/.bashrc.alex ]; then
	echo "Creating link to .bashrc.alex - Remember to source from .bashrc"
	ln -s $PWD/dot-bashrc-dot-alex $HOME/.bashrc.alex
fi
if [ ! -e $HOME/.tmuxinator ]; then
	echo "Creating link to .tmuxinator"
	ln -s $PWD/dot-tmuxinator $HOME/.tmuxinator
fi

if [ ! -e $HOME/.zshrc ]; then
	echo "Creating link to .zshrc"
	ln -s $PWD/dot-zshrc $HOME/.zshrc
fi

if [ ! -e $HOME/.gitconfig ]; then
	echo "Creating link to .gitconfig"
	ln -s $PWD/dot-gitconfig $HOME/.gitconfig
fi
