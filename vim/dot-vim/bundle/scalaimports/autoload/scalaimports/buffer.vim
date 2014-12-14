function! scalaimports#buffer#update_unambiguous_imports()
  let import_state = scalaimports#file#imports_state()
  for [package, class] in scalaimports#file#unambiguous_imports()
    call scalaimports#state#add_import(import_state, package, class)
  endfor
  call scalaimports#file#replace_import_lines(import_state)
endfunction

function! scalaimports#buffer#create()
  call scalaimports#buffer#update_unambiguous_imports()
  let import_state = scalaimports#file#imports_state()  
  let buffer_width = cage433utils#sum(scalaimports#buffer#column_widths(import_state)) + 5

  exec 'silent! ' . buffer_width . 'vnew __IMPORTS__'
  let b:import_state = import_state
  setlocal noshowcmd
  setlocal noswapfile
  setlocal buftype=nofile
  "setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nowrap
  setlocal nonumber
  call scalaimports#buffer#redraw()

  function! Chosen_package()
    return b:import_state.classes_and_packages_to_import[line('.') - 1][0]
  endfunction
  function! Chosen_class()
    return b:import_state.classes_and_packages_to_import[line('.') - 1][1]
  endfunction
  function! Add_chosen(package, class) 
    call scalaimports#state#add_import(b:import_state, package, class)
    call scalaimports#file#replace_import_lines(b:import_state)
    call scalaimports#buffer#redraw()
  endfunction

  map <silent> <buffer> <F5> :bwipeout<CR> 
  map <silent> <buffer> <CR> :silent! call Add_chosen(Chosen_package(), Chosen_class())<CR>
  map <silent> <buffer> p :silent! call Add_chosen(Chosen_package(), "_")<CR>

endfunction

function! scalaimports#buffer#column_widths(import_state)
  let class_column_width = max(map(a:import_state.classes_and_packages_to_import, 'strlen(v:val[0])'))
  let package_column_width = max(map(a:import_state.classes_and_packages_to_import, 'strlen(v:val[1])'))

  return [class_column_width, package_column_width]
endfunction

function! scalaimports#buffer#redraw()
  setlocal modifiable
  let [class_column_width, package_column_width] = scalaimports#buffer#column_widths(b:import_state)
  let blank_class = repeat(" ", class_column_width)
  function! Left_justify(str)
    return str + repeat(" ", class_column_width - strlen(str))
  endfunction
  exec ':normal! ggdG'
  let last_class = ""
  let lines = []
  for [class, package] in b:import_state.classes_and_packages_to_import
    if class == last_class
      let class_term = blank_class
    else
      let class_term = Left_justify(class, class_column_width)
    endif
    call add(lines, class_term . " " . package . " ")
    let last_class = class
  endfor
  silent put! =lines

  " trim last line and move to line number
  norm! GkJ
  setlocal nomodifiable
endfunction
