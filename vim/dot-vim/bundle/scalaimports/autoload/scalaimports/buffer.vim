function! scalaimports#buffer#update_unambiguous_imports(import_state)

  let unambiguous_imports = scalaimports#state#unambiguous_imports(a:import_state)
  if ! empty(unambiguous_imports )
    call scalaimports#state#add_imports(a:import_state, unambiguous_imports)
    call scalaimports#file#replace_import_lines(a:import_state)
  endif
endfunction

function! scalaimports#buffer#create()
  if bufexists(bufnr("__IMPORTS__"))
    exec ':' . bufnr("__IMPORTS__") . 'bwipeout'
    return
  endif
  let import_state = scalaimports#file#imports_state()  
  silent call scalaimports#buffer#update_unambiguous_imports(import_state)
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
  setlocal bufhidden=delete
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
    " Call to add_import modifies b:import_state in place
    silent! call scalaimports#state#add_import(b:import_state, a:package, a:class)
    silent! call scalaimports#file#replace_import_lines(b:import_state)
    let b:line_number = line('.')
    call scalaimports#buffer#redraw()
  endfunction

  map <silent> <buffer> <F5> :bwipeout<CR> 
  map <silent> <buffer> <CR> :silent! call Add_chosen(Chosen_package(), Chosen_class())<CR>
  map <silent> <buffer> p :silent! call Add_chosen(Chosen_package(), "_")<CR>
  map <silent> <buffer> J :call search('\v^\w', "W")<CR>
  map <silent> <buffer> K :call search('\v^\w', "bW")<CR>

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
  exec ':normal! ggdG'
  let last_class = ""
  let lines = []
  for [class, package] in b:potential_imports
    let class_term = class == last_class ? blank_class : cage433utils#left_justify(class, class_column_width)
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
