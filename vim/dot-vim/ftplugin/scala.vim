function! ToggleScalaComment()
  if (match(getline('.'), '^\/\/') == 0)
    exec "normal! mj:s/\\/\\///\<cr>`jhh"
  else
    exec "normal! mj:s/^/\\/\\//\<cr>`jll"
  endif
endfunction

noremap <C-c> :call ToggleScalaComment()<cr>
