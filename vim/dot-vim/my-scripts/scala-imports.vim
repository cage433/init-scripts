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

function! AddClass(hash, package, classes)
  if has_key(a:hash, a:package) && a:hash[a:package] == ["_"]
    " do nothing - already imports entire package
  elseif a:classes == ["_"]
    let a:hash[a:package] = ["_"]
  else
    let a:hash[a:package] = extend(get(a:hash, a:package, []), a:classes)
  endif
endfunction

function! AllImports()
  let lines = readfile(expand('%'))
  let import_lines = filter(lines, 'v:val =~ ''\v^import ''')
  let imported_classes = {}

  for line in import_lines
    let l = matchlist(line, '\vimport ([a-z0-9.]+)\.(\S+)')
    if !empty(l)
      let classes = split(substitute(l[2], '\v\{|\}', "", "g"), '\v, *')
      call AddClass(imported_classes, l[1], classes)
    endif
  endfor

  return imported_classes
endfunction

function! ClassesUsed()
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

    elseif line =~ '\v^\w*$'                                      " ignore whitespace

    elseif ! in_comment
      let words = split(line, '\v[^A-Za-z0-9_.]+')                " Split into words, leaving full stops
      let words = map(copy(words), 'split(v:val, ''\.'')[0]')     " Take the left of full stop - dropping constants
                                                                  " Like MyClass.Constant
      for word in words                                           " Collect terms that look like classes/objects
        if word =~ '\v^[A-Z]\w+'                              
          let classes[word] = 1
        endif
      endfor
    endif
  endfor
  return sort(keys(classes))
endfunction
" call AddImports("Resource", "List", "Set")
