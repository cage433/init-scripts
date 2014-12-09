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
    @packages = Hash.new{ |hash, file| hash[file] = {}}
    (IO.readlines(packages_by_file_file) rescue []).each do
      |line|
        file, klass, package = line.chomp.split("\t")
        @packages[file][klass] = package
    end
  end

  def write_to_file()
    File.open(packages_by_file_file, "w") do |f|
      @packages.each do |file, package_map|
        package_map.each do |klass, package|
          f.puts("#{file}\t#{klass}\t#{package}")
        end
      end
    end
  end

  def write_class_packages_to_file()
    map = Hash.new{|hash, key| hash[key] = []}
    @packages.each{ |file, packages| 
      packages.each{ |klass, package|
        map[klass] << package
      }
    }
    File.open(packages_for_class_file, "w") do |f|
      map.sort.each{
        |klass, packages|

          f.puts("#{klass} #{packages.sort.join(",")}")
      }
    end
  end

  def remove_old_files()
    old_files = stale_files()
    return if old_files.empty?
    #puts("Deleting #{old_files.size} file(s)")
    old_files.each{|jar_file| @packages.delete(jar_file)}
  end

  def add_missing_files()
    new_files = files_to_add()
    return if (new_files.empty?)
    #puts("Processing #{new_files.size} file(s)")

    files_per_thread = 5
    queue = Queue.new
    threads = new_files.each_slice(files_per_thread).collect{ |slice|
      Thread.new{
        slice.each{
          |file|
            file_class_packages = process_file(file)
            if !file_class_packages.empty?
              queue << [file, process_file(file)]
            end
        }
      }
    }
    threads.each{|th| th.join}
    while !queue.empty?
      file, packages = queue.pop
      if packages
        @packages[file] = packages
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

  def files_to_add()
    source_files = Dir.glob("*/src/**/*.scala") + Dir.glob("*/tests/**/*.scala") 
    if File.exists?(packages_by_file_file)
      last_time = File.mtime(packages_by_file_file)
    else
      last_time = Time.new(0)
    end

    source_files.select{|file|
      if ! @packages.include?(file)
        true
      else
        File.mtime(file) > last_time
      end
    }
  end

  def process_file(source_file)
    project_classes = []
    lines = IO.readlines(source_file)
    if !lines.empty? && lines[0] =~ /^package\s+([a-z0-9.]+).*$/
      package = $1

      lines.each do |line|
        if line =~ /\s*(class|trait|object)\s+([A-Z]\w+)/ then
          project_classes << [$2, package]
        end
      end
    end
    project_classes
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
    (Dir.glob("*/lib_managed/*.jar") << "#{ENV["JAVA_HOME"]}/jre/lib/rt.jar" << "scala-libs/scala-library-2.9.2.jar").compact.uniq { |file|
      File.basename(file)
    }
  end

  def stale_files()
    project_jar_basenames = project_jar_files.collect{|jar_file| File.basename(jar_file)}
    @packages.keys.select{|jar_file, _| !project_jar_basenames.include?(File.basename(jar_file))}
  end

  def files_to_add()
    jar_basenames = @packages.keys.collect{|jar_file| File.basename(jar_file)}
    project_jar_files.select{
      |jar_file| 
        ! jar_basenames.include?(File.basename(jar_file))
    }
  end

  def process_file(jar_file)
    map = {}
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

        map[klass] = pckg
        
      end
    end
    map
  end
end

ProjectPackages.new().sync_with_project
ExternalPackages.new().sync_with_project


