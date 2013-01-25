#!/usr/bin/ruby -w

$: << File.dirname(__FILE__)

require 'optparse'
require 'find'
require 'fileutils'

$cmd = nil
$short_class = nil

optparse = OptionParser.new do |opts|
  opts.on("-c", "--clean", "Clean import listings") do 
      $cmd = :clean
  end
  opts.on("-u", "--update", "Update import listings") do 
      $cmd = :update
  end
  opts.on("-p", "--project-imports klass", "Output project import(s) for klass") do |klass|
      $cmd = :output_project_imports
      $short_class = klass
  end
  opts.on("-e", "--external-imports klass", "Find external imports(s) for klass") do |klass|
      $cmd = :output_external_imports
      $short_class = klass
  end
  opts.on("-j", "--open-java-doc klass", "Open java doc page for klass") do |klass|
      $cmd = :open_java_doc
      $short_class = klass
  end
  opts.on("-s", "--open-scala-doc klass", "Open scala doc page for klass") do |klass|
      $cmd = :open_scala_doc
      $short_class = klass
  end
  opts.on("-h", "--help", "Show this message") do 
    puts "\n#{optparse}"
    exit 0
  end
end
optparse.parse!


dot_maker_dot_vim = "#{Dir.pwd}/.maker.vim"
Dir.mkdir(dot_maker_dot_vim) unless File.exists?(dot_maker_dot_vim)

$project_packages_file = "#{dot_maker_dot_vim}/project_packages"
$external_packages_file = "#{dot_maker_dot_vim}/external_packages"



# process project source code

def write_project_packages
  puts "Processing project"

  def package_name_from_file(file)
    dirs = File.dirname(file).split("/").reverse
    i = dirs.index("src") || dirs.index("tests") || dirs.index("model-src")
    i && dirs[0..i-1].reverse.join(".")
  end

  project_classes = []
  Find.find(Dir.pwd) do |file|
    if File.expand_path(file) == File.expand_path("project")
      Find.prune
    elsif file =~ /.*\.scala$/ then
      IO.readlines(file).each do |line|
        if line =~ /\s*(class|trait|object)\s*(\w+)\s*(private)?\s*(((extends)|(with))\s+\w+\s*)*(\{|\[|\(|$)/ then
          if package_name_from_file(file) then 
            project_classes << [$2, package_name_from_file(file)]
          end
        end
      end
    end
  end

  File.open($project_packages_file, "w") do |f|
    project_classes.uniq.each do |x|
      klass, pckg = x
      f.puts("#{klass}\t#{pckg}")
    end
  end
end


# process external jars

def read_stored_external_packages
  (IO.readlines($external_packages_file) rescue []).collect do
    |line|
      line.chomp.split("\t")
  end
end

def read_packages_file(file_name)
  (IO.readlines(file_name) rescue []).collect do
    |line|
      line.chomp.split("\t")
  end
end

$java_jar = 
  if RUBY_PLATFORM.downcase.include?("linux")
    java_home = ENV["JAVA_HOME"] || (raise "JAVA_HOME not set")
    "#{java_home}/jre/lib/rt.jar"
  elsif RUBY_PLATFORM.downcase.include?("darwin")
    "/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Classes/classes.jar"
  end

$scala_jars = 
  begin
    scala_root = ENV["SCALA_HOME"] || (raise "SCALA_HOME not set")
    ["#{scala_root}/lib/scala-library.jar", "#{scala_root}/lib/scala-compiler.jar"]
  end

def project_jars 
  jars = $scala_jars
  jars << $java_jar

  Find.find(Dir.pwd) do |file|
    if File.expand_path(file) == File.expand_path("project") \
      || File.expand_path(file) == File.expand_path("maker.jar") \
      || File.basename(file) == ".maker" \
      || File.basename(file) == "modulejarcache" \
      || file =~ /sources/
      Find.prune
    elsif file =~ /\.jar$/
      jars << file
    end
  end
  jars
end

def write_external_packages

  external_packages = read_packages_file($external_packages_file)
  jars_already_processed = external_packages.collect{ |jar, _, _| jar}.uniq

  jar_files_to_add = project_jars.select{|jar| ! jars_already_processed.include?(File.basename(jar))}

  jar_files_to_add.each do |jar|
    puts "Processing #{jar}"
    `jar tvf #{jar}`.split("\n").each do |line|
      if line =~ /(\S+)\.class/ then
        file_name = $1
        pckg = File.dirname(file_name).split("/").join(".")
        klass = File.basename(file_name, ".class")
        # Only use the outermost class
        external_packages << [File.basename(jar), pckg, klass.split('$').first]
      end
    end
  end

  external_packages = external_packages.uniq

  # Remove any jars that aren't in project
  project_jar_names = project_jars.collect{|jar_file| File.basename(jar_file)}
  external_packages = external_packages.select{ |jar, _, _|
    project_jar_names.include?(jar)
  }

  File.open($external_packages_file, "w") do |f|
    external_packages.each do |jar, pckg, klass|
      f.puts("#{File.basename(jar)}\t#{pckg}\t#{klass}")
    end 
  end
end

def display_url(url)
  `DISPLAY=:\"0.0\" google-chrome #{url}`
end

case $cmd
when :clean
  FileUtils.rm_rf([$external_packages_file, $project_packages_file])

when :update
  write_project_packages
  write_external_packages

when :output_external_imports
  read_packages_file($external_packages_file).each{
    |_, pckg, klass_| 
      if klass_ == $short_class
        puts "import #{pckg}.#{$short_class}"
      end
  }

when :output_project_imports
  read_packages_file($project_packages_file).each{
    |klass_, pckg|
    #klass_, pckg = line.chomp.split("\t")
    if klass_ == $short_class
      puts "import #{pckg}.#{$short_class}"
    end
  }

when :open_java_doc
  read_packages_file($external_packages_file).select{
    |jar, _, klass|
      File.basename($java_jar) == jar && klass == $short_class
  }.take(1).each{
    |_, pckg, _|
      display_url("http://docs.oracle.com/javase/6/docs/api/#{pckg.gsub(".", "/")}/#{$short_class}.html")
  }

when :open_scala_doc
  scala_jar_basenames = $scala_jars.collect{ |jar| File.basename(jar) }
  read_packages_file($external_packages_file).select{
    |jar, _, klass|
      scala_jar_basenames.include?(jar) && klass == $short_class
  }.take(1).each{
    |_, pckg, _|

      display_url("http://www.scala-lang.org/api/current/#{pckg.gsub(".", "/")}/#{$short_class}.html")
  }
end

