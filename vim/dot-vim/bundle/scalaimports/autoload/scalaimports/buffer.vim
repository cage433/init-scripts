function! scalaimports#buffer#update_unambiguous_imports()
  let import_state = scalaimports#file#imports_state()
  let unambiguous_imports = scalaimports#file#unambiguous_imports(import_state)
  if ! empty(unambiguous_imports )
    echo "Adding unambiguous"
    for [package, class] in unambiguous_imports
      call scalaimports#state#add_import(import_state, package, class)
    endfor
    call scalaimports#file#replace_import_lines(import_state)
  endif
endfunction

function! scalaimports#buffer#create()
  silent! call scalaimports#buffer#update_unambiguous_imports()
  let import_state = scalaimports#file#imports_state()  
  if empty(import_state.classes_to_import)
    echo "No more imports"
    return
  endif

  exec 'silent! vnew __IMPORTS__'
  let b:import_state = import_state
  let b:line_number = 1
  setlocal noshowcmd
  setlocal noswapfile
  setlocal buftype=nofile
  "setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nowrap
  setlocal nonumber
  call scalaimports#buffer#redraw()

  function! Chosen_package()
    return b:potential_imports[line('.') - 1][1]
  endfunction
  function! Chosen_class()
    return b:potential_imports[line('.') - 1][0]
  endfunction
  function! Add_chosen(package, class) 
    let b:import_state = scalaimports#state#add_import(b:import_state, a:package, a:class)
    call scalaimports#file#replace_import_lines(b:import_state)
    let b:line_number = line('.')
    call scalaimports#buffer#redraw()
  endfunction

  map <silent> <buffer> <F5> :bwipeout<CR> 
  map <silent> <buffer> <CR> :silent! call Add_chosen(Chosen_package(), Chosen_class())<CR>
  map <silent> <buffer> p :silent! call Add_chosen(Chosen_package(), "_")<CR>

endfunction

function! scalaimports#buffer#column_widths(import_state)
  let class_column_width = max(map(copy(b:potential_imports), 'strlen(v:val[0])'))
  let package_column_width = max(map(copy(b:potential_imports), 'strlen(v:val[1])'))

  return [class_column_width, package_column_width]
endfunction

function! scalaimports#buffer#update_potential_imports()
  let b:potential_imports = []
  for class in b:import_state.classes_to_import
    for package in scalaimports#project#packages_for_class(class)
      call add(b:potential_imports, [class, package])
    endfor
  endfor
endfunction

function! scalaimports#buffer#redraw()
  setlocal modifiable
  call scalaimports#buffer#update_potential_imports()
  let [class_column_width, package_column_width] = scalaimports#buffer#column_widths(b:import_state)
  let buffer_width = class_column_width + package_column_width + 5
  exec ":vertical resize ".buffer_width
  let blank_class = repeat(" ", class_column_width)
  function! Left_justify(column_width, str)
    return a:str . repeat(" ", a:column_width - strlen(a:str))
  endfunction
  exec ':normal! ggdG'
  let last_class = ""
  let lines = []
  for [class, package] in b:potential_imports
    if class == last_class
      let class_term = blank_class
    else
      let class_term = Left_justify(class_column_width, class)
    endif
    call add(lines, class_term . " " . package . " ")
    let last_class = class
  endfor
  if empty(lines)
    exec ":bw"
  else
    silent put! =lines

    " trim last line and move to line number
    norm! GkJ
    exec "norm! ".b:line_number."G0"
    setlocal nomodifiable
  endif
endfunction
