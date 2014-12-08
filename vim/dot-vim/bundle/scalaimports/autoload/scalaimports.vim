function! scalaimports#imports_map()
  if !exists('g:scala_imports_map')
    let package_file = ".maker.vim/external_packages/by_class_name"
    if !filereadable(package_file)
      echo "Rebuilding package file"
      exec ":silent ! ruby " . expand_path(%:h") . "/scala-imports.rb"
    endif
    let g:scala_imports_map = {}
    for line in readfile(package_file)
      let class_and_packages = split(line, " ")
      let packages_list = split(class_and_packages[1], ",")
      let g:scala_imports_map[class_and_packages[0]] = packages_list
    endfor
    echo "Loaded scala imports"
  endif
  return g:scala_imports_map
endfunction

function! scalaimports#packages_for_class(klass)
  return get(scalaimports#imports_map(), a:klass, [])
endfunction

function! scalaimports#longest_package_name_for_class(klass)
  return max(
  \       map(
  \         copy(scalaimports#packages_for_class(a:klass)), 
  \         'strlen(v:val)'))
endfunction

function! scalaimports#longest_package_name(classes)
  return max( 
  \    map(copy(a:classes), 
  \    'scalaimports#longest_package_name_for_class(v:val)'))
endfunction 
