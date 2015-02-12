" Returns a dict describing the imports as they are in 
" a scala file - which must be the current buffer
"
" These can have more imports added, and be written back to the file

let s:import_regex='\v^import\s+([a-zA-Z0-9.]+)\.([a-zA-Z0-9_\{} \t,=>]+)\s*$'
let s:package_regex='\v^package\s+(.*)$'

function! scalaimports#file#parse_import_text(import_text)
  let match = matchlist(a:import_text, s:import_regex)
  let package = match[1]
  let classes = split(substitute(match[2], '\v\s|\{|}', "", "g"), ",")
  return [package, classes]
endfunction

function! scalaimports#file#imports_state()
  let state = {}
  let state.packages = []
  let state.importees_for_package = {}
  let import_lines = filter(
    \ cage433utils#lines_in_current_buffer(),
    \ "v:val =~ '".s:import_regex."'")

  let state.import_lines_for_package = {} " Map[Package, import_line]
  for [package, classes] in map(import_lines, 'scalaimports#file#parse_import_text(v:val)')
    let classes_set = cage433utils#list_to_set(classes)
    call scalaimports#state#extend_imports_for_package(state, package, classes)
  endfor
  let state.scala_file_package = scalaimports#file#scala_package()
  let state.scala_file_buffer_name = bufname('%')

  let state.classes_to_import = []
  for class in scalaimports#file#classes_mentioned()
    if ! scalaimports#state#already_imported(state, class)
        \ && ! empty(scalaimports#project#packages_for_class(class))
      call add(state.classes_to_import, class)
    endif
  endfor

  return state
endfunction

function! scalaimports#file#scala_package()
  let package_line = cage433utils#find(
    \ cage433utils#lines_in_current_buffer(),
    \ "_ =~ '".s:package_regex."'")
  if empty(package_line)
    throw "No package for buffer ".bufname('%')
  endif

  return matchlist(package_line[0], s:package_regex)[1]
endfunction

function! scalaimports#file#imports_range()
  let lines = cage433utils#lines_in_current_buffer()
  let idx_of_first_line = cage433utils#index_of(lines, "_ =~ '".s:import_regex."'")
  if idx_of_first_line == -1 " No imports
    return []
  else
    let idx_of_last_line = cage433utils#index_of(lines, "_ =~ '".s:import_regex."'", 0)
    " line numbers are 1 based
    return [idx_of_first_line + 1, idx_of_last_line + 1]
  endif
endfunction

function! scalaimports#file#replace_import_lines(import_state)
  let saved_buffer_name = bufname("")
  call cage433utils#jump_to_buffer_window(a:import_state.scala_file_buffer_name)
  let import_range = scalaimports#file#imports_range()

  let line_to_write = empty(import_range) ? 3 : import_range[0]
  " delete all import lines
  call SaveWinline()
  let current_line_no = line('.')
  let cursor_below_imports = empty(import_range) ? current_line_no > 3 : current_line_no > import_range[1]
  if cursor_below_imports
    exec ":normal! mz"
  endif
  exec ":g/".s:import_regex."/d"
  exec ":normal! ".line_to_write."G"
  put! =scalaimports#state#import_lines(a:import_state)

  if cursor_below_imports
    exec ":normal! `z"
  else
    exec ":normal! ".current_line_no."G"
  endif
  call RestoreWinline()
  exec ":w"
  call cage433utils#jump_to_buffer_window(saved_buffer_name)
endfunction

function! scalaimports#file#classes_mentioned()
  let classes ={}
  let in_comment = 0
  for line in cage433utils#lines_in_current_buffer()
    let line = substitute(line, '\v//.*$', "", "g")               " Remove '//' comments
    let line = substitute(line, '\v/\*[^/*]*\*/', "", "g")        " Remove one line '/*...*/' comments
    let line = substitute(line, '\v"[^"]"', "", "g")                " Remove literal strings
    if line =~ '\v^\s*import|^package'                            " ignore import/package lines

    elseif line =~ '\v^\s*/\*'                                    " multiline comment started - ignore all till end
      let in_comment = 1
    elseif line =~ '\v\s*\*/'                                     " multiline comment ended
      let in_comment = 0
    elseif line =~ '\v^\s*\*'                                      " middle of scaladoc comment - ignore

    elseif line =~ '\v^\s*$'                                      " ignore whitespace

    elseif ! in_comment
      let words = filter(
        \ split(line, '\v[^A-Za-z0-9_.]+'),                
        \ 'v:val != "."')
      for word in words
          if  len(split(word, '\.')) == 0
            echo word
            echo line
          endif
      endfor
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

