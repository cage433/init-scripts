#!/usr/bin/ruby -w

require 'fileutils'

scala_file = ARGV[0] || raise("No file given")
FileUtils.cp(scala_file, "/tmp/#{File.basename(scala_file)}")
all_lines = IO.readlines(scala_file)
first_line_after_imports = all_lines.drop(1).index do |line|
  line !~ /^import/ and line !~ /^\s*$/
end


import_lines = all_lines[0...first_line_after_imports].select{|line| line =~ /^import /}
regular_imports = {}
import_all_in_object = {}
import_alls = []

class Hash
  def push(key, value)
    if !self[key] then
      self[key] = []
    end
    self[key].push(value)
  end
end

import_lines.each do |line|
  line =~ /import\s+([a-z.]*)\.(.*)/
  package, rest = $1, $2.strip
  if rest =~ /\{(.*)\}/ then
    $1.split(",").each { |importee|
      regular_imports.push(package, importee)
    }
  elsif rest == "_" then
    import_alls.push(package)
  elsif rest =~ /\._/ then
    import_all_in_object.push(package, rest)
  else
    regular_imports.push(package, rest)
  end
end


packages = (regular_imports.keys + import_alls + import_all_in_object.keys).uniq.sort

File.open(scala_file, "w") do |s|
  s.puts(all_lines[0])
  s.puts
  packages.each do |package|
    if regular_imports[package] then
      s.print "import #{package}"
      importees = regular_imports[package]
      if importees.size > 1 then
        s.puts(".{#{importees.sort.join(", ")}}")
      else
        s.puts(".#{importees[0]}")
      end
    end
    if import_all_in_object[package]  then
      importees = import_all_in_object[package]
      importees.each do |imp|
        s.puts "import #{package}.#{imp}"
      end
    end
    if import_alls.member?(package) then
      s.puts "import #{package}._"
    end
  end
  s.puts
  all_lines[first_line_after_imports..-1].each do |line|
    s.print(line)
  end
end


