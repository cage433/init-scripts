#!/usr/bin/ruby -w

require 'fileutils'
home = ENV["HOME"]
pwd = Dir.pwd


links = [
  [ "#{home}/.vim", "#{pwd}/vim/dot-vim" ],
  [ "#{home}/.vimrc", "#{pwd}/vim/dot-vimrc" ],
  [ "#{home}/.ctags", "#{pwd}/dot-ctags" ],
  [ "#{home}/.tmux.conf", "#{pwd}/dot-tmux-dot-conf" ],
  [ "#{home}/.tmux.colemak.conf", "#{pwd}/colemak/tmux.conf" ],
  [ "#{home}/.ackrc", "#{pwd}/dot-ackrc" ],
  [ "#{home}/.gitconfig", "#{pwd}/dot-gitconfig" ]
]

links.each do |dest, src|
  if ! File.exists?(dest)
    puts "Creating link from #{src} to #{dest}"
    FileUtils.symlink(src, dest)
  end
end

vim_plugins = [
  "git@github.com:mileszs/ack.vim",
  "git@github.com:vim-scripts/bufferlist.vim",
  "git@github.com:vim-scripts/bufkill.vim",
  "git@github.com:kien/ctrlp.vim",
  "git@github.com:sjl/splice.vim",
  "git@github.com:MarcWeber/vim-addon-mw-utils",
  "git@github.com:altercation/vim-colors-solarized",
  "git@github.com:tpope/vim-fugitive",
  "git@github.com:garbas/vim-snipmate",
  "git@github.com:xolox/vim-misc",
  "git@github.com:xolox/vim-reload",
  "git@github.com:vim-scripts/ZoomWin"
]

Dir.chdir("#{home}/.vim/bundle"){

  vim_plugins.each do |repo|
    basename = File.basename(repo.split(":")[1])
    if ! File.exists?(basename)
      puts "Cloning #{repo}"
      `git clone #{repo}`
    else
      Dir.chdir(basename){
        puts "Updating #{repo}"
        `git pull`
      }
    end
  end
}


