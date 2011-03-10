#!/usr/bin/ruby -w

require 'find'

starling_classes = []
$external_classes = []
do_external_classes = ARGV.index("-e")

def package_name(file)
  dirs = File.dirname(file).split("/").reverse
  i = dirs.index("starling")
  raise dirs.to_s unless i
  dirs[0..i].reverse.join(".")
end

$jars_to_extract = [/colt-1.2/]
def is_jar_to_extract(file)
  file =~/.*\.jar$/ && file !~ /modulejar/ #&& $jars_to_extract.find{ |jar_regex| file =~ jar_regex}
end

def extract_jar(file)
  `jar tvf #{file}`.split("\n").each do |line|
    if line =~ /(\S+)\.class/
      file_name = $1
      pckg = File.dirname(file_name).split("/").join(".")
      klass = File.basename(file_name, ".class")
      if klass !~ /\$/ then
        $external_classes.unshift([klass, pckg])
      end
    end
  end
end
#Find.find("/home/alex/dev/services/starling") do |file|
Find.find(Dir.pwd) do |file|
  if file =~ /.*\.scala$/ then
    IO.readlines(file).each do |line|
      if line =~ /\s*(class|trait|object)\s*(\w+)\s*(private)?\s*(((extends)|(with))\s+\w+\s*)*(\{|\[|\(|$)/ then
        starling_classes.unshift([$2, package_name(file)])
      end
    end
  elsif do_external_classes && is_jar_to_extract(file) then
    puts file
    extract_jar(file)
  end
end

if do_external_classes then
  extract_jar("/usr/local/jdk/jre/lib/rt.jar")
end

File.open("#{Dir.pwd}/starling_imports", "w") do |f|
  starling_classes.each do |x|
    klass, pckg = x
    f.puts("#{klass}\t#{pckg}")
  end
end

if do_external_classes then
  File.open("#{Dir.pwd}/external_imports", "w") do |f|
    $external_classes.each do |x|
      klass, pckg = x
      f.puts("#{klass}\t#{pckg}")
    end
  end
end
