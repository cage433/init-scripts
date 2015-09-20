set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'altercation/vim-colors-solarized'

Plugin 'cage433/cage433-vim-utils'
Plugin 'cage433/cage433-vim-ide-plugin'

Plugin 'kien/ctrlp.vim'
Plugin 'mileszs/ack.vim'
Plugin 'vim-scripts/bufferlist.vim'
Plugin 'vim-scripts/BufOnly.vim'
Plugin 'derekwyatt/vim-scala'
Plugin 'tpope/vim-fugitive'
Plugin 'cage433/scalaimports'
Plugin 'scrooloose/nerdcommenter'
Plugin 'tpope/vim-fireplace'
Plugin 'tpope/vim-eunuch'
Plugin 'L9'
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

"Needed to force vim-colors-solarized to autoload
" See https://github.com/altercation/vim-colors-solarized/issues/40
call togglebg#map("")
set wildignore +=*.xml,*.sha1,*.html,tags,by_source_file,by_class
call scalaimports#state#ignore_classes(['Either', 'Left', 'Right', 'Version'])

if filereadable(".vim.settings")
  exec "source".".vim.settings"
endif
color solarized
set ruler
set rulerformat=%55(%{strftime('%a\ %b\ %e\ %I:%M\ %p')}\ %5l,%-6(%c%V%)\ %P%)
