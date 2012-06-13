#!/usr/bin/ruby -w

$: << File.dirname(__FILE__)

require 'optparse'
require 'find'
require 'fileutils'

options = {}

optparse = OptionParser.new do |opts|
  opts.on("-c", "--clean", "Clean import listings") do 
      options[:clean] = true
  end
  opts.on("-u", "--update", "Update import listings") do 
      options[:update] = true
  end
  opts.on("-p", "--project-imports klass", "Output project import(s) for klass") do |klass|
      options[:project_class] = klass
  end
  opts.on("-e", "--external-imports klass", "Find external imports(s) for klass") do |klass|
      options[:external_class] = klass
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

if options[:clean]
  FileUtils.rm_rf([$external_packages_file, $project_packages_file])
end


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

def find_project_jar_files
  scala_root = ENV["SCALA_HOME"] || (raise "SCALA_HOME not set")
  project_jars = ["#{scala_root}/lib/scala-library.jar", "#{scala_root}/lib/scala-compiler.jar"]

  if RUBY_PLATFORM.downcase.include?("linux")
    java_home = ENV["JAVA_HOME"] || (raise "JAVA_HOME not set")
    project_jars << "#{java_home}/jre/lib/rt.jar"
  elsif RUBY_PLATFORM.downcase.include?("darwin")
    project_jars << "/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Classes/classes.jar"
  end
  Find.find(Dir.pwd) do |file|
    if File.expand_path(file) == File.expand_path("project") \
      || File.expand_path(file) == File.expand_path("maker.jar") \
      || File.basename(file) == ".maker" \
      || File.basename(file) == "modulejarcache" \
      || file =~ /sources/
      Find.prune
    elsif file =~ /\.jar$/
      project_jars << file
    end
  end
  project_jars
end

def write_external_packages

  external_packages = read_stored_external_packages
  jars_already_processed = external_packages.collect{ |jar, _, _| jar}.uniq

  project_jar_files = find_project_jar_files

  jar_files_to_add = project_jar_files.select{|jar| ! jars_already_processed.include?(File.basename(jar))}

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
  project_jar_names = project_jar_files.collect{|jar_file| File.basename(jar_file)}
  external_packages = external_packages.select{ |jar, _, _|
    project_jar_names.include?(jar)
  }

  File.open($external_packages_file, "w") do |f|
    external_packages.each do |jar, pckg, klass|
      f.puts("#{File.basename(jar)}\t#{pckg}\t#{klass}")
    end 
  end
end

if options[:update]
  write_project_packages
  write_external_packages
end

klass = options[:external_class]
if klass
  read_stored_external_packages.each { 
    |_, pckg, klass_| 
      if klass == klass_
        puts "import #{pckg}.#{klass}"
      end
  }
end

klass = options[:project_class]
if klass
  (IO.readlines($project_packages_file) rescue []).each { |line|
    klass_, pckg = line.chomp.split("\t")
    if klass_ == klass
      puts "import #{pckg}.#{klass}"
    end
  }
end
