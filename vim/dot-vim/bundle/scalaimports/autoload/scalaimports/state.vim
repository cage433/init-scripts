" Maintains the state of imports in a scala file

let g:packages_in_scope = {"scala" : 1, "java.lang" : 1}
let g:scala_predef_classes = {"Set" : 1, "List" : 1, "Any" : 1, "Map" : 1}


function! scalaimports#state#already_imported(state, class) 
  if has_key(g:scala_predef_classes, a:class)
    return 1
  endif
  for package in scalaimports#project#packages_for_class(a:class)
    let classes = get(a:state.classes_for_package, package, [])
    if classes == ["_"]
      \ || cage433utils#list_contains(classes, a:class)
      \ || has_key(g:packages_in_scope, package)
      \ || package == a:state.scala_file_package
      return 1
    endif
  endfor
  return 0
endfunction

" Note that this modifies `state`
" After its execution `state` may not be consistent until
function! scalaimports#state#add_single_import(state, package, class) 
  let classes_ = get(a:state.classes_for_package, a:package, [])
  if ! cage433utils#list_contains(classes_, a:class)
    call add(classes_, a:class)
    if len(classes_) >= 4
        \ || strlen(join(classes_, "")) + strlen(a:package) > 80
        \ || cage433utils#list_contains(classes_, "_")
        \ || a:class == "_"
      let a:state.classes_for_package[a:package] = ["_"]
    else
      let a:state.classes_for_package[a:package] = classes_
    endif
  endif
  if ! cage433utils#list_contains(a:state.packages, a:package)
    let a:state.packages += [a:package]
  endif
endfunction

function! scalaimports#state#update_classes_to_import(state)
  let filtered_classes_to_import = []
  for class in a:state.classes_to_import
    if ! scalaimports#state#already_imported(a:state, class)
          \ && ! empty(scalaimports#project#packages_for_class(class))
      call add(filtered_classes_to_import, class)
    endif
  endfor
  let a:state.classes_to_import = filtered_classes_to_import
endfunction

" Note that this modifies `state`
function! scalaimports#state#add_import(state, package, class) 
  call scalaimports#state#add_single_import(a:state, a:package, a:class) 
  call scalaimports#state#update_classes_to_import(a:state)
endfunction

function! scalaimports#state#add_imports(state, package_class_pairs) 
  for [package, class] in a:package_class_pairs
    call scalaimports#state#add_single_import(a:state, package, class)
  endfor
  call scalaimports#state#update_classes_to_import(a:state)
endfunction

function! scalaimports#state#import_lines(state) 
  let lines = []
  for package in a:state.packages
    let classes = get(a:state.classes_for_package, package, [])
    let line = "import ".package."."
    if len(classes) == 1
      let line .=  classes[0]
    else
      let line .= "{".join(classes, ", ")."}"
    endif
    call add(lines, line)
  endfor
  return lines
endfunction

function! scalaimports#state#unambiguous_imports(import_state)
  let unambiguous = []
  for class in a:import_state.classes_to_import
    " If we have a unique package in source then use that
    " otherwise see if we have a unique package across the project
    let packages = scalaimports#project#source_packages_for_class(class)
    if empty(packages)
    let packages = scalaimports#project#packages_for_class(class)
    endif
    if len(packages) == 1 && !scalaimports#state#already_imported(a:import_state, class) 
      call add(unambiguous, [packages[0], class])
    endif
  endfor
  return unambiguous
endfunction


