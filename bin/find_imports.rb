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
add_imports("#{ENV['HOME']}/starling/starling_imports")
if include_external then
  add_imports("#{ENV['HOME']}/starling/external_imports")
end

puts $imports
