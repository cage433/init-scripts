" Amends import lines minimally.
function! Package_and_importee(import)
  let match = matchlist(a:import, '\vimport\s+([a-zA-Z0-9.]+)\.([a-zA-Z0-9_\{} \t,]+)\s*$')
  if empty(match)
    return match
  else
    return [match[1], match[2]]
  endif
endfunction

function! Imported_classes(importee)
  let classes = substitute(a:importee, '\v\s|\{|}', "", "g")
  return split(classes, ",")
endfunction


function! Tidy_imports(imports)
  let packages = {}
  let packages_list = []

  for import in a:imports
    let [package, importee] = Package_and_importee(import)
    let classes = Imported_classes(importee)
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
  let lines = []
  for p in packages_list
    let importee = ""
    if len(packages[p]) > 1
      let importee = "{".join(packages[p], ", ")."}"
    else
      let importee = packages[p][0]
    end
    call add(lines, "import ".p.".".importee)
  endfor
  return lines
endfunction

for imp in Tidy_imports(imports)
  echo imp
endfor
