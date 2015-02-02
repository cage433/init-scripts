#!/usr/bin/ruby -w
#

require 'thread'
require 'fileutils'
require 'optparse'

dot_maker_dot_vim = "#{Dir.pwd}/.maker.vim"

$project_packages_file = "#{dot_maker_dot_vim}/project_packages"

class Packages

  def packages_by_file_file 
    raise "This should be overriden"
  end

  def packages_for_class_file
    raise "This should be overriden"
  end

  def files_to_add()
    raise "This should be overriden"
  end

  def files_per_thread()
    raise "This should be overriden"
  end

  def stale_files()
    raise "This should be overriden"
  end

  def process_file(file)
    raise "This should be overriden"
  end

  def initialize()
    load_from_file
  end

  def sync_with_project
    remove_old_files()
    add_missing_files()
    write_to_file()
    write_class_packages_to_file()
  end

  private

  def load_from_file()
    # `file` can be a source file or jar
    @packages = Hash.new{ |hash, file| hash[file] = [] }
    (IO.readlines(packages_by_file_file) rescue []).each do
      |line|
        file, klass, package = line.chomp.split("\t")
        @packages[file] << [klass, package]
    end
  end

  def write_to_file()
    File.open(packages_by_file_file, "w") do |f|
      @packages.each do |file, class_package_pairs|
        class_package_pairs.each do |klass, package|
          f.puts("#{file}\t#{klass}\t#{package}")
        end
      end
    end
  end

  def write_class_packages_to_file()
    map = Hash.new{|hash, klass| hash[klass] = []}
    @packages.each{ |file, class_package_pairs| 
      class_package_pairs.each do |klass, package|
          map[klass] << package
      end
    }
    File.open(packages_for_class_file, "w") do |f|
      map.sort.each{
        |klass, packages|

          f.puts("#{klass} #{packages.uniq.sort.join(",")}")
      }
    end
  end

  def remove_old_files()
    old_files = stale_files()
    return if old_files.empty?
    old_files.each{|jar_file| @packages.delete(jar_file)}
  end

  def add_missing_files()
    new_files = files_to_add()
    return if (new_files.empty?)

    queue = Queue.new
    threads = new_files.each_slice(files_per_thread).collect{ |slice|
      Thread.new{
        slice.each{
          |file|
            file_class_packages_pairs = process_file(file)
            if !file_class_packages_pairs.empty?
              queue << [file, process_file(file)]
            end
        }
      }
    }
    threads.each{|th| th.join}
    while !queue.empty?
      file, class_package_pairs = queue.pop
      if class_package_pairs
        @packages[file] = class_package_pairs
      end
    end
  end
end

class ProjectPackages < Packages
  def initialize
    @packages_dir = "#{Dir.pwd}/.maker.vim/project_packages"
    FileUtils.mkdir_p(@packages_dir)
    super
  end
  def packages_by_file_file 
    "#{@packages_dir}/by_source_file"
  end

  def packages_for_class_file
    "#{@packages_dir}/by_class"
  end

  def stale_files()
    @packages.keys.select{|file| ! File.exists?(file)}
  end

  def files_per_thread
    3000
  end
  def files_to_add()
    source_files = Dir.glob("*/src/**/[A-Z]*.scala") + Dir.glob("*/tests/**/[A-Z]*.scala") 
    if File.exists?(packages_by_file_file)
      last_time = File.mtime(packages_by_file_file)
    else
      last_time = Time.new(0)
    end

    files = source_files.select{|file|
      if ! @packages.include?(file)
        true
      else
        File.mtime(file) > last_time
      end
    }
    if files.size > 10
      puts "Processing #{files.size} scala files"
    end
    files
  end

  def find_package(file)
    File.foreach(file).find_index{|line| 
      if line =~ /^package\s+([A-Za-z0-9.]+)$/
        return $1
      end
    }
    nil
  end
  def process_file(source_file)
    class_package_pairs = []
    package = find_package(source_file)
    lines = IO.readlines(source_file)

    if !lines.empty? && package

      lines.each do |line|
        if line =~ /\s*(class|trait|object)\s+([A-Z]\w+)/ then
          class_package_pairs << [$2, package]
        end
      end
    end
    class_package_pairs
  end
end

class ExternalPackages < Packages

  def initialize
    @external_packages_dir = "#{Dir.pwd}/.maker.vim/external_packages"
    FileUtils.mkdir_p(@external_packages_dir)
    super
  end
  def packages_by_file_file 
    "#{@external_packages_dir}/by_jar"
  end

  def packages_for_class_file
    "#{@external_packages_dir}/by_class"
  end


  private


  def project_jar_files
    scala_library = Dir.glob("scala-libs/scala-library*.jar").select{|jar| ! jar.include?("source")}
    (Dir.glob("**/lib_managed/*.jar") + scala_library << "#{ENV["JAVA_HOME"]}/jre/lib/rt.jar").compact.uniq { |file|
      File.basename(file)
    }
  end

  def stale_files()
    project_jar_basenames = project_jar_files.collect{|jar_file| File.basename(jar_file)}
    @packages.keys.select{|jar_file, _| !project_jar_basenames.include?(File.basename(jar_file))}
  end

  def files_per_thread
    10
  end
  def files_to_add()
    jar_basenames = @packages.keys.collect{|jar_file| File.basename(jar_file)}
    jars = project_jar_files.select{
      |jar_file| 
        ! jar_basenames.include?(File.basename(jar_file))
    }
    if jars.size > 10
      puts "Processing #{jars.size} jars"
    end
    jars
  end

  def process_file(jar_file)
    class_package_pairs = []
    `$JAVA_HOME/bin/jar tvf #{jar_file}`.split("\n").each do |line|
      if line =~ /(\S+\/[A-Z][^.]+)\.class/ then  
        relative_class_file = $1
        pckg = File.dirname(relative_class_file).split("/").join(".")
        # Strip of anything after '$' from the class name, as source
        # won't contain that
        klass = File.basename(relative_class_file, ".class").split('$').first
        if klass.strip.empty?
          puts("Bad class in #{jar_file}")
          puts("line = #{line}")
          exit 0
        end
        class_package_pairs << [klass, pckg]

      end
    end
    class_package_pairs
  end
end

ProjectPackages.new().sync_with_project
ExternalPackages.new().sync_with_project


