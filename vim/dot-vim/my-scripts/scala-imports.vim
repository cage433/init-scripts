"nnoremap <silent> <F5> :source %<CR>|echo "Loaded"


function! SortTuple(t1, t2)
    if a:t1[0] == a:t2[0]
      return a:t1[1] > a:t2[1]
    else
      return a:t1[0] > a:t2[0]
    endif
endfunction

function! UpdateImport(scala_file_buffer_no, package)
  exec ":b " . a:scala_file_buffer_no
  exec ":normal mz"
  call SaveWinline()
  silent exec "normal! G?^import\\|^package\<cr>"
  :normal "j"
  put ='import ' . a:package
  exec ":normal `z"
  call RestoreWinline()
endfunction

function! AddImports(...)
  let scala_file_buffer_no = bufnr('%')
  let imports_map=scalaimports#imports_map()
  let classes = a:000
  let class_column_width = max(map(copy(classes), 'strlen(v:val)'))
  let package_column_width = scalaimports#longest_package_name(classes)
  let buffer_width = class_column_width + package_column_width + 2

  function! Make_blank(width)
    return repeat(" ", a:width)
  endfunction

  function! Left_justify(text, width)
    return a:text . Make_blank(a:width - strlen(a:text))
  endfunction

  let lines = []
  for class in classes
    let first_line = 1
    let packages = scalaimports#packages_for_class(class)
    for package in packages
      if first_line == 1
        let class_term = Left_justify(class, class_column_width)
      else
        let class_term = Make_blank(class_column_width)
      endif
      call add(lines, class_term . " " . package . " ")
      let first_line = 0
    endfor

  endfor


"  let a:name = a:1
"  let split_lines = map(deepcopy(matching_lines), 'split(v:val, "\t")')
"  let classes_and_packages = sort(map(deepcopy(split_lines), '[v:val[2], v:val[1]]'), function("SortTuple"))
"
"  let class_column_width = max(map(deepcopy(classes_and_packages), 'strlen(v:val[0])'))
"  let width = max(map(deepcopy(classes_and_packages), 'strlen(v:val[1]) + class_column_width')) + 5
"
"  let last_class = ""
"  let lines = []
"  for c_and_p in classes_and_packages
"    
"    if c_and_p[0] == last_class
"      let class_term = ""
"    else
"      let class_term = c_and_p[0]
"      let last_class = c_and_p[0]
"    endif
"    let line = class_term . repeat(" ", class_column_width - strlen(class_term)) . "   " . c_and_p[1]
"    call add(lines, line)
"  endfor
"


  exec 'silent! ' . buffer_width . 'vne __IMPORTS__'
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

call AddImports("Resource", "List", "Set")
