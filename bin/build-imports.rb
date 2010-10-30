#!/usr/bin/ruby -w

require 'find'

starling_classes = []
external_classes = []
do_external_classes = ARGV.index("-e")

def package_name(file)
  dirs = File.dirname(file).split("/").reverse
  i = dirs.index("starling")
  raise dirs.to_s unless i
  dirs[0..i].reverse.join(".")
end

Find.find("/home/alex/starling") do |file|
  if file =~ /.*\.scala$/ then
    puts file
    IO.readlines(file).each do |line|
      if line =~ /\s*(class|trait)\s*(\w+)\s*(private)?\s*\(/ then
        puts line
        starling_classes.unshift([$2, package_name(file)])
      end
    end
  elsif file =~/.*\.jar$/ && do_external_classes then
    `jar tvf #{file}`.split("\n").each do |line|
      if line =~ /(\S+)\.class/
        pckg = File.dirname($1).split("/").join(".")
        klass = File.basename($1, ".class")
        external_classes.unshift([klass, pckg])
      end
    end
  end
end

File.open("/home/alex/starling/starling_imports", "w") do |f|
  starling_classes.each do |x|
    klass, pckg = x
    f.puts("#{klass}\t#{pckg}")
  end
end

if do_external_classes then
  external_classes.each do |x|
    File.open("/home/alex/starling/external_imports", "w") do |f|
      external_classes.each do |x|
        klass, pckg = x
        f.puts("#{klass}\t#{pckg}")
      end
    end
  end
end
