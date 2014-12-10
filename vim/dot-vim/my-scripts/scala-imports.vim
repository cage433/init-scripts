function! UpdateImports()
  let classes = scalaimports#classes_in_buffer_needing_import()
  call scalaimports#launch_import_buffer(classes)
endfunction

function! ClassesUsed()
  let result = scalaimports#classes_referred_to_in_buffer()
  return result
endfunction



