#!/usr/bin/ruby -w

require 'find'

project_classes = []
$project_jars=[]
do_external_jars = ARGV.index("-e")

def package_name(file)
  dirs = File.dirname(file).split("/").reverse
  i = dirs.index("src")
  raise dirs.to_s unless i
  dirs[0..i-1].reverse.join(".")
end

def is_jar_to_extract(file)
  file =~/.*\.jar$/ && file !~ /modulejar/ 
end

Find.find(Dir.pwd) do |file|
  if file =~ /.*\.scala$/ then
    IO.readlines(file).each do |line|
      if line =~ /\s*(class|trait|object)\s*(\w+)\s*(private)?\s*(((extends)|(with))\s+\w+\s*)*(\{|\[|\(|$)/ then
        project_classes.unshift([$2, package_name(file)])
      end
    end
  elsif do_external_jars && is_jar_to_extract(file) then
    $project_jars.unshift(file)
  end
end


File.open("#{Dir.pwd}/.maker/project_imports", "w") do |f|
  project_classes.each do |x|
    klass, pckg = x
    f.puts("#{klass}\t#{pckg}")
  end
end

def extract_jars_to_file(jar_files, output_file)
  File.open(output_file, "w") do |f|
    jar_files.each do |file|

      `jar tvf #{file}`.split("\n").each do |line|
        if line =~ /(\S+)\.class/
          file_name = $1
          pckg = File.dirname(file_name).split("/").join(".")
          klass = File.basename(file_name, ".class")
          if klass !~ /\$/ then
            f.puts("#{klass}\t#{pckg}")
          end
        end
      end
    end
  end

end

if do_external_jars then
  java_classes_jar = if RUBY_PLATFORM.downcase.include?("darwin") then 
    "/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Classes/classes.jar"
  elsif RUBY_PLATFORM.downcase.include?("linux")
    "/usr/local/jdk/jre/lib/rt.jar"
  else
    raise("Unrecognised platform #{RUBY_PLATFORM}")
  end
  extract_jars_to_file([java_classes_jar], "#{Dir.pwd}/.maker/java_imports")
  extract_jars_to_file($project_jars,  "#{Dir.pwd}/.maker/external_imports")
end
