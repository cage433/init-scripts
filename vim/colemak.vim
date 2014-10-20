"function! Colemak()
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Colemak-Vim Mappings
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " HNEI arrows.
    noremap n j|noremap e k|noremap i l|noremap gn gj|noremap ge gk
  " In(s)ert. The default s/S is synonymous with cl/cc and is not very useful.
    noremap s i|noremap S I
  " Last search.
    noremap k n|noremap K N
  " BOL/EOL/Join Lines.
    noremap l ^|noremap L $|noremap <C-l> J
    onoremap r i
  " End of word.
    noremap j e|noremap J E
    nnoremap <C-h> <C-w>h
    nnoremap <C-n> <C-w>j
    nnoremap <C-e> <C-w>k
    nnoremap <C-k> <C-e>
    nnoremap <C-i> <C-w>l
    inoremap ii <ESC>
"endfunction

