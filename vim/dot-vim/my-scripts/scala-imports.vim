"nnoremap <silent> <F5> :source %<CR>|echo "Loaded"

function! SortTuple(t1, t2)
    if a:t1[0] == a:t2[0]
      return a:t1[1] > a:t2[1]
    else
      return a:t1[0] > a:t2[0]
    endif
endfunction

function! AddImports(...)
  let a:name = a:1
  let package_file = ".maker.vim/external_packages"
  if !filereadable(package_file)
    echo "No package file exists"
    return 1
  endif
  let my_regexp='\t\(' . join(a:000, '\|') . '\)$'
  let matching_lines = filter(readfile(package_file), 'v:val =~ my_regexp')
  if len(matching_lines) == 0
    echo "No package found for " . a:name
    return 1
  endif
  let split_lines = map(deepcopy(matching_lines), 'split(v:val, "\t")')
  let classes_and_packages = sort(map(deepcopy(split_lines), '[v:val[2], v:val[1]]'), function("SortTuple"))

  let class_column_width = max(map(deepcopy(classes_and_packages), 'strlen(v:val[0])'))
  let width = max(map(deepcopy(classes_and_packages), 'strlen(v:val[1]) + class_column_width')) + 5

  let last_class = ""
  let lines = []
  for c_and_p in classes_and_packages
    
    if c_and_p[0] == last_class
      let class_term = ""
    else
      let class_term = c_and_p[0]
      let last_class = c_and_p[0]
    endif
    let line = class_term . repeat(" ", class_column_width - strlen(class_term)) . "   " . c_and_p[1]
    call add(lines, line)
  endfor



  exec 'silent! ' . width . 'vne __IMPORTS__'
  setlocal noshowcmd
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nowrap
  setlocal nonumber
  setlocal modifiable
  silent put! =lines

  " trim last line and move to top
  norm! GkJgg0

  setlocal nomodifiable

  map <silent> <buffer> <F5> :bwipeout<CR> 
endfunction

" call AddImports("Resource", "List", "Set")
