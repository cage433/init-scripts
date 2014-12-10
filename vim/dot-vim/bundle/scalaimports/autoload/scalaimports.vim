if exists('g:ScalaImportsLoaded')
  finish
endif
let g:ScalaImportsLoaded = 1

function! s:write_import_line(scala_file_buffer_no, import_line)
  let imports_buffer_no = bufnr('%')
  exec ":b " . a:scala_file_buffer_no
  exec ":normal mz"
  call SaveWinline()
  silent exec "normal! G?^import\\|^package\<cr>"
  :normal "j"
  put =a:import_line
  exec ":normal `z"
  call RestoreWinline()
  exec ":b " . imports_buffer_no
endfunction


function! s:update_imports_map(imports_map, imports_file)
  if !filereadable(a:imports_file)
    echo "Rebuilding package file"
    exec ":silent ! ruby $HOME/repos/init-scripts/vim/dot-vim/my-scripts/scala-imports.rb" 
  endif
  for line in readfile(a:imports_file)
    let [class, packages] = split(line, " ")
    let packages_list = split(packages, ",")
    let a:imports_map[class] = packages_list + get(a:imports_map, class, [])
  endfor
endfunction

function! s:imports_map()
  if !exists('g:scala_imports_map')
    let g:scala_imports_map = {}

    call s:update_imports_map(g:scala_imports_map, '.maker.vim/external_packages/by_class')
    call s:update_imports_map(g:scala_imports_map, '.maker.vim/project_packages/by_class')
  endif
  return g:scala_imports_map
endfunction

function! s:packages_for_class(klass)
  return get(s:imports_map(), a:klass, [])
endfunction

function! s:longest_package_name_for_class(klass)
  return max(
  \       map(
  \         copy(s:packages_for_class(a:klass)), 
  \         'strlen(v:val)'))
endfunction

function! s:longest_package_name(classes)
  return max( 
  \    map(copy(a:classes), 
  \    's:longest_package_name_for_class(v:val)'))
endfunction 

function! s:imported_classes_and_packages_in_buffer()
  let lines = readfile(expand('%'))
  let import_lines = filter(lines, 'v:val =~ ''\v^import ''')
  let imported_packages = {}
  let imported_classes = {}

  for line in import_lines
    let l = matchlist(line, '\vimport\s+([a-z0-9.]+)\.([{}a-zA-Z0-9_, ]+)\s*$')
    if !empty(l)
      let classes = split(substitute(l[2], '\v\{|\}', "", "g"), '\v, *')
      if classes == ["_"]
        let imported_packages[l[1]] = 1
      else
        for class in classes
          let imported_classes[class] = 1
        endfor
      endif
    endif
  endfor

  return [imported_classes, imported_packages]
endfunction

function! s:classes_referred_to_in_buffer()
  let classes ={}
  let in_comment = 0
  for line in readfile(expand('%'))
    let line = substitute(line, '\v//.*$', "", "g")               " Remove '//' comments
    let line = substitute(line, '\v/\*[^/*]*\*/', "", "g")        " Remove one line '/*...*/' comments
    let line = substitute(line, '\v".*"', "", "g")                " Remove literal strings
    if line =~ '\v^\s*import|^package'                            " ignore import/package lines

    elseif line =~ '\v^\s*/\*'                                    " multiline comment started - ignore all till end
      let in_comment = 1
    elseif line =~ '\v\s*\*/'                                     " multiline comment ended
      let in_comment = 0
    elseif line =~ '\v\s*\*'                                      " middle of scaladoc comment - ignore

    elseif line =~ '\v^\s*$'                                      " ignore whitespace

    elseif ! in_comment
      let words = split(line, '\v[^A-Za-z0-9_.]+')                " Split into words, leaving full stops
      let words = map(copy(words), 'split(v:val, ''\.'')[0]')     " Take the left of full stop - dropping constants
                                                                  " like MyClass.Constant
      for word in words                                           " Collect terms that look like classes/objects
        if word =~ '\v^[A-Z]\w+'                              
          let classes[word] = 1
        endif
      endfor
    endif
  endfor
  return sort(keys(classes))
endfunction

function! s:this_buffers_package()
  let first_line = readfile(expand('%'), '', 1)
  let matches = matchlist(first_line, '\v^package\s+(.*)$')
  if len(matches) >= 2
    return matches[1]
  else
    return ""
  endif
endfunction

let s:packages_in_scope = {"scala" : 1, "java.lang" : 1}
let s:scala_predef_classes = {"Set" : 1, "List" : 1, "Any" : 1, "Map" : 1}

function! scalaimports#classes_in_buffer_needing_import()
  let [imported_classes, imported_packages] = s:imported_classes_and_packages_in_buffer()
  let this_package = s:this_buffers_package()
  let classes = ClassesUsed()
  let to_import = {}
  for class in classes
    if has_key(imported_classes, class) || has_key(s:scala_predef_classes, class)
      " ignore - we have this class
    else
      let packages = s:packages_for_class(class)
      let needs_importing = 1
      for package in packages
        if has_key(imported_packages, package)  || package == this_package || has_key(s:packages_in_scope, package)
          let needs_importing = 0
        endif
      endfor
      if needs_importing == 1
        let to_import[class] = 1
      endif
    endif
  endfor
  return sort(keys(to_import))
endfunction

function! AddImport()
  let i = line('.') - 1
  call s:write_import_line(b:scala_file_buffer_no, "import ".b:packages_by_line[i].".".b:classes_by_line[i])
endfunction

function! scalaimports#launch_import_buffer(classes)
  let scala_file_buffer_no = bufnr('%')
  let imports_map=s:imports_map()
  let class_column_width = max(map(copy(a:classes), 'strlen(v:val)'))
  let package_column_width = s:longest_package_name(a:classes)
  let buffer_width = class_column_width + package_column_width + 2

  function! Make_blank(width)
    return repeat(" ", a:width)
  endfunction

  function! Left_justify(text, width)
    return a:text . Make_blank(a:width - strlen(a:text))
  endfunction

  let lines = []
  let classes_by_line=[]
  let packages_by_line=[]
  for class in a:classes
    let first_line = 1
    let packages = s:packages_for_class(class)
    for package in packages
      if first_line == 1
        let class_term = Left_justify(class, class_column_width)
      else
        let class_term = Make_blank(class_column_width)
      endif
      call add(classes_by_line, class)
      call add(packages_by_line, package)
      call add(lines, class_term . " " . package . " ")
      let first_line = 0
    endfor

  endfor



  exec 'silent! ' . buffer_width . 'vne __IMPORTS__'
  let b:scala_file_buffer_no = scala_file_buffer_no
  let b:classes_by_line = classes_by_line
  let b:packages_by_line = packages_by_line
  setlocal noshowcmd
  setlocal noswapfile
  setlocal buftype=nofile
  "setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nowrap
  setlocal nonumber
  setlocal modifiable
  silent put! =lines

  " trim last line and move to top
  norm! GkJgg0

  setlocal nomodifiable

  map <silent> <buffer> <F5> :bwipeout<CR> 
  map <silent> <buffer> <CR> :call AddImport()<CR>

endfunction


