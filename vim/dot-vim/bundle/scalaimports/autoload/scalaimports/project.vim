let s:this_script_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
function! scalaimports#project#add_file_to_imports_map(imports_file)
  for line in readfile(a:imports_file)
    let [class, packages] = split(line, " ")
    let packages_list = split(packages, ",")
    let g:scala_imports_map[class] = packages_list + get(g:scala_imports_map, class, [])
  endfor
endfunction

function! scalaimports#project#rebuild_imports_map(purge_package_file)
  if a:purge_package_file
    silent exec ":! rm -rf .maker.vim/external_packages/"
    silent exec ":! rm -rf .maker.vim/project_packages/"
    redraw!
  endif
  let g:scala_imports_map = {}
  echo "Rebuilding package file"
  silent exec ":! ruby ".s:this_script_dir."/scala-imports.rb" 
  redraw!
  call scalaimports#project#add_file_to_imports_map('.maker.vim/external_packages/by_class')
  call scalaimports#project#add_file_to_imports_map('.maker.vim/project_packages/by_class')
  :redraw!
endfunction

function! scalaimports#project#imports_map()
  if !exists('g:scala_imports_map')
    call scalaimports#project#rebuild_imports_map(0)
  endif
  return g:scala_imports_map
endfunction

function! scalaimports#project#packages_for_class(klass)
  return get(scalaimports#project#imports_map(), a:klass, [])
endfunction

