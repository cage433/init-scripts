#!/usr/bin/ruby -w

$short_name = ARGV[0]

include_external = ARGV.index("-a")
$imports = []

def add_imports(file)
  regexp = /^#{$short_name}\s+((\w|\.)+)/
  IO.readlines(file).each do |line|
    if line =~ regexp
      $imports.unshift("import #{$1}.#{$short_name}")
    end
  end
end
add_imports("#{Dir.pwd}/.maker/project_imports")
if include_external then
  add_imports("#{Dir.pwd}/.maker/external_imports")
  add_imports("#{Dir.pwd}/.maker/java_imports")
  add_imports("#{Dir.pwd}/.maker/scala_imports")
end

puts $imports.uniq
