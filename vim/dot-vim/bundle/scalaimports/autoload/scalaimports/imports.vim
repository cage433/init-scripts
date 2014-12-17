function! scalaimports#imports#importee(term)
  let term = substitute(a:term, '\v\s', '', 'g')
  let import = {}
  " defaults
  let import.is_package_import = 0
  let import.class = ""
  let import.class_rename = ""
  let import.to_string = term

  if term == "_"
    let import.is_package_import = 1
  else
    let match = matchlist(term, '\v([^=>]+)\s*\=\>\s*([^=>]+)')
    if empty(match)
      let import.class = term
    else
      let import.class = match[1]
      let import.class_rename = match[2]
      let import.to_string = import.class." => ".import.class_rename
    endif
  endif
  
  function! import.imports_class(class) dict
    if self.is_package_import
      return 1
    elseif self.class_rename != ""
      return self.class_rename == a:class
    else
      return self.class == a:class
    endif
  endfunction

  return import

endfunction

function! scalaimports#imports#import_line(package, terms)
  let import_line = {}
  let import_line.importees = []
  let import_line.package = a:package

  function! import_line.imports_class(class) dict
    for importee in self.importees
      if importee.imports_class(a:class)
        return 1
      endif
    endfor
    return 0
  endfunction

  function! import_line.to_string() dict
    let imports_as_string = join(map(self.importees, 'v:val.to_string'), ", ")
      
    let import = ""
    if len(self.importees) > 1 || self.importees[0].class_rename != ""
      let import = '{' . imports_as_string . '}'
    else
      let import = self.importees[0].to_string
    endif
    let p = self.package
    return p.'.'.import
  endfunction

  function! import_line.add_importee(new_importee) dict
    if a:new_importee.is_package_import
      let self.importees = [a:new_importee]
    elseif ! self.imports_class(a:new_importee.class)
      call add(self.importees, a:new_importee)
    endif

 "   if len(self.importees) >= 4 || strlen(join(keys(importees), "")) + strlen(a:package) > 80
  endfunction

  for term in a:terms
    let importee = scalaimports#imports#importee(term)
    call import_line.add_importee(importee)
  endfor

  return import_line
endfunction

let il = scalaimports#imports#import_line("foo.bar", ["Fred", "mike", "Alex =>    Ruby"])
echo il.to_string()

