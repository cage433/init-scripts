#!/usr/bin/ruby -w

$: << File.dirname(__FILE__)
require 'utils.rb'

$short_name = ARGV[0]

include_external = ARGV.index("-a")
$imports = []

def add_imports(file)
  packages = find_packages($short_name, file)
  $imports = $imports + packages.collect{|p| "import #{p}.#{$short_name}"}
end
add_imports($project_packages)
if include_external then
  add_imports($external_packages)
  add_imports($java_packages)
  add_imports($scala_packages)
end

puts $imports.uniq
