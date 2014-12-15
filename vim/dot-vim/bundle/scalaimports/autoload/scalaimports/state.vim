" Maintains the state of imports in a scala file

let g:packages_in_scope = {"scala" : 1, "java.lang" : 1}
let g:scala_predef_classes = {"Set" : 1, "List" : 1, "Any" : 1, "Map" : 1}


function! scalaimports#state#already_imported(state, class) 
  if has_key(g:scala_predef_classes, a:class)
    return 1
  endif
  for package in scalaimports#project#packages_for_class(a:class)
    let classes = get(a:state.importees_for_package, package, {})
    if has_key(classes , "_")
      \ || has_key(classes, a:class)
      \ || has_key(g:packages_in_scope, package)
      \ || package == a:state.scala_file_package
      return 1
    endif
  endfor
  return 0
endfunction

" Note that this modifies `state`
" After its execution `state` may not be consistent until
" `update_classes_to_import is called
function! scalaimports#state#extend_imports_for_package(state, package, new_importees) 

  let importees = cage433utils#get_or_update(a:state.importees_for_package, a:package, {})
  if has_key(importees, "_")
    " Already importing the whole package
    return
  else
    if has_key(a:new_importees, "_")
      let a:state.importees_for_package[a:package] = {"_" : 1}
    else
      for importee in keys(a:new_importees)
        if ! has_key(importees, importee)
          let importees[importee] = 1
          if len(importees) >= 4 || strlen(join(keys(importees), "")) + strlen(a:package) > 80
            let a:state.importees_for_package[a:package] = {"_" : 1}
            break " out of for
          endif
        endif
      endfor
    endif
    if ! cage433utils#list_contains(a:state.packages, a:package)
      let a:state.packages += [a:package]
    endif
  endif
endfunction

function! scalaimports#state#update_classes_to_import(state)
  let filtered_classes_to_import = []
  for class in a:state.classes_to_import
    if ! scalaimports#state#already_imported(a:state, class)
      call add(filtered_classes_to_import, class)
    endif
  endfor
  let a:state.classes_to_import = filtered_classes_to_import
endfunction

" Note that this modifies `state`
function! scalaimports#state#add_import(state, package, class) 
  call scalaimports#state#extend_imports_for_package(a:state, a:package, {a:class : 1}) 
  call scalaimports#state#update_classes_to_import(a:state)
endfunction

function! scalaimports#state#add_imports(state, package_class_pairs) 
  for [package, class] in a:package_class_pairs
    call scalaimports#state#extend_imports_for_package(a:state, package, {class : 1})
  endfor
  call scalaimports#state#update_classes_to_import(a:state)
endfunction

function! scalaimports#state#import_lines(state) 
  let lines = []
  for package in a:state.packages
    let classes = get(a:state.importees_for_package, package, {})
    let line = "import ".package."."
    if len(classes) == 1
      let line .=  keys(classes)[0]
    else
      let line .= "{".join(keys(classes), ", ")."}"
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


