" Amends import lines minimally.



let g:import_regex='\v^import\s+([a-zA-Z0-9.]+)\.([a-zA-Z0-9_\{} \t,]+)\s*$'

function! Package_and_importee(import)
  let match = matchlist(a:import, g:import_regex)
  if empty(match)
    return match
  else
    let package = match[1]
    let classes = split(substitute(match[2], '\v\s|\{|}', "", "g"), ",")
    return [package, classes]
  endif
endfunction

function! ToImportText(package, classes)
  if len(a:classes) == 1
    return a:package.".".a:classes[0]
  elseif len(a:classes) > 4
    return a:package."._"
  else
    return a:package.".{".join(a:classes, ", ")."}"
  endif
endfunction


function! CombineImports(imports)
  let packages = {}
  let packages_list = []

  for [package, classes] in a:imports
    if has_key(packages, package)
      if packages[package] == ["_"] || classes == ["_"]
        let packages[package] = ["_"]
      else
        let packages[package] += classes
      endif
    else
      let packages[package] = classes
      call add(packages_list, package)
    endif
  endfor
  let combined = []
  for p in packages_list
    call add(combined,  [p, packages[p]])
  endfor
  return combined
endfunction

function! Imports_range()
  let lines = getbufline(bufnr('%'), 1, "$")
  let idx_of_first_line = cage433utils#index_of(lines, "_ =~ '".g:import_regex."'")
  if idx_of_first_line == -1 " No imports
    return []
  else
    let idx_of_last_line = cage433utils#index_of(lines, "_ =~ '".g:import_regex."'", 0)
    " line numbers are 1 based
    return [idx_of_first_line + 1, idx_of_last_line + 1]
  endif
endfunction

function! CurrentImports()
  let import_lines = filter(getbufline(bufnr('%'), 1, "$"), "v:val =~ '".g:import_regex."'")
  return map(import_lines, "Package_and_importee(v:val)")
endfunction

function! ReplaceImportLines(new_import_lines)
  let import_range = Imports_range()

  let line_to_write = 3
  if ! empty(import_range)
    let line_to_write = import_range[0]
  endif
  " delete all import lines
  call SaveWinline()
  let current_line_no = line('.')
  let cursor_below_imports = !empty(import_range) && current_line_no > import_range[1]
  if cursor_below_imports
    exec ":normal mz"
  endif
  exec ":g/".g:import_regex."/d"
  exec ":normal ".line_to_write."G"
  put! =a:new_import_lines

  if cursor_below_imports
    exec ":normal `z"
  else
    exec ":normal ".current_line_no."G"
  endif
  call RestoreWinline()
endfunction

function! ReplaceImports(window_no, new_imports)
  let saved_window_no = winnr()
  exec ":normal ".a:window_no."\<C-w>w"
  let current_imports = CurrentImports()
  let combined_imports = CombineImports(current_imports + a:new_imports)
  echo combined_imports[0]
  let import_text = map(copy(combined_imports), "ToImportText(v:val[0], v:val[1])")
  call ReplaceImportLines(import_text)
  exec ":normal ".saved_window_no."\<C-w>w"
endfunction


