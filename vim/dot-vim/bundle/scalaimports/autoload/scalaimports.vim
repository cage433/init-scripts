function! scalaimports#imports_map()
  if !exists('g:scala_imports_map')
    let g:scala_imports_map = {}

    call scalaimports#update_imports_map(g:scala_imports_map, '.maker.vim/external_packages/by_class')
    call scalaimports#update_imports_map(g:scala_imports_map, '.maker.vim/project_packages/by_class')
  endif
  return g:scala_imports_map
endfunction

function! scalaimports#update_imports_map(imports_map, imports_file)
  if !filereadable(a:imports_file)
    echo "Rebuilding package file"
    exec ":silent ! ruby $HOME/repos/init-scripts/vim/dot-vim/my-scripts/scala-imports.rb" 
  endif
  echo "Reading file"
  for line in readfile(a:imports_file)
    if (len(split(line, "")) < 2)
      echo "bad line " . line
    end
    if (len(split(line, "")) > 2)
      echo "bad line " . line
    end
    let [class, packages] = split(line, " ")
    let packages_list = split(packages, ",")
    let a:imports_map[class] = packages_list + get(a:imports_map, class, [])
  endfor
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
