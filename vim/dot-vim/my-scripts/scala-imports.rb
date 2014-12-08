#!/usr/bin/ruby -w
#

require 'thread'
require 'fileutils'
require 'optparse'

dot_maker_dot_vim = "#{Dir.pwd}/.maker.vim"

$project_packages_file = "#{dot_maker_dot_vim}/project_packages"
$external_packages_dir = "#{dot_maker_dot_vim}/external_packages"
FileUtils.mkdir_p($external_packages_dir)
$external_packages_by_jar_file = "#{$external_packages_dir}/by_jar"
$external_packages_by_class_name_file = "#{$external_packages_dir}/by_class_name"


class ExternalPackages
  attr_reader :jar_packages
  def initialize()
    sync_with_file()
  end

  def sync_with_project
    remove_old_jars
    add_missing_jars
    write_to_file()
    write_class_packages_to_file()
  end

  private

  def write_class_packages_to_file()
    map = Hash.new{|hash, key| hash[key] = []}
    @jar_packages.each{ |jar_file, packages| 
      packages.each{ |klass, package|
        map[klass] << package
      }
    }
    File.open($external_packages_by_class_name_file, "w") do |f|
      map.sort.each{
        |klass, packages|
          f.puts("#{klass} #{packages.sort.join(",")}")
      }
    end
  end
  def write_to_file()
    File.open($external_packages_by_jar_file, "w") do |f|
      @jar_packages.each do |jar_file, package_map|
        package_map.each do |klass, package|
          f.puts("#{jar_file}\t#{klass}\t#{package}")
        end
      end
    end
  end

  def sync_with_file()
    @jar_packages = Hash.new{ |hash, jar_file| hash[jar_file] = {}}
    (IO.readlines($external_packages_by_jar_file) rescue []).each do
      |line|
        jar_file, klass, package = line.chomp.split("\t")
        @jar_packages[jar_file][klass] = package
    end
  end

  def project_jar_files
    (Dir.glob("*/lib_managed/*.jar") << "#{ENV["JAVA_HOME"]}/jre/lib/rt.jar").compact.uniq { |file|
      File.basename(file)
    }
  end

  def remove_old_jars
    project_jar_basenames = project_jar_files.collect{|jar_file| File.basename(jar_file)}
    old_jars = @jar_packages.keys.select{|jar_file, _| !project_jar_basenames.include?(File.basename(jar_file))}
    return if old_jars.empty?
    puts("Deleting #{old_jars.size} jar(s)")
    old_jars.each{|jar_file| @jar_packages.delete(jar_file)}
  end

  def add_missing_jars
    jar_basenames = @jar_packages.keys.collect{|jar_file| File.basename(jar_file)}
    new_jars = project_jar_files.select{
      |jar_file| 
        ! jar_basenames.include?(File.basename(jar_file))
    }
    return if (new_jars.empty?)
    puts("Processing #{new_jars.size} jar(s)")

    jars_per_thread = 5
    queue = Queue.new
    threads = new_jars.each_slice(jars_per_thread).collect{ |slice|
      Thread.new{
        slice.each{
          |jar_file|
            queue << [jar_file, class_packages_from_jar(jar_file)]
        }
      }
    }
    threads.each{|th| th.join}
    while !queue.empty?
      jar_file, packages = queue.pop
      @jar_packages[jar_file] = packages
    end
  end

  def class_packages_from_jar(jar_file)
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

ps = ExternalPackages.new()
ps.sync_with_project


