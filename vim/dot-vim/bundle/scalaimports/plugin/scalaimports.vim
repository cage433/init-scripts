function! UpdateImports()
  let update_occurred = scalaimports#file#update_unambiguous_imports()
  let import_state = scalaimports#file#imports_state()  
  let classes = scalaimports#file#classes_mentioned()
  let classes_needing_import = filter(classes, '! import_state.AlreadyImported(v:val)')
  if ! empty(classes_needing_import)
    call scalaimports#buffer#create(import_state, classes_needing_import)
  elseif update_occurred
    echo "Imports updated"
  else
    echo "No imports needed"
  endif
endfunction

function! RedrawImportsBuffer()
endfunction
