#!/usr/bin/ruby

require 'find'
require 'fileutils'

from, to = ARGV

raise "Usage rename-class.rb <from> <to>" unless (from && to)

def replace_basename(file, new_basename)
  File.dirname(file) + "/" + new_basename + ".scala"
end
# replace all text
Find.find(".") do |file|
  if file =~ /\.scala/ then
    source = IO.readlines(file)
    new_source = source.collect do |line|
      line.gsub(/\b#{from}\b/, to)
    end
    basename = File.basename(file)
    new_file = if basename == "#{from}.scala" then
                 replace_basename(file, to)
               elsif basename =~ /\b#{from}Test/ then
                 replace_basename(file, basename.gsub(/\b{from}/, to))
               else
                 file
               end

    File.open(new_file, "w+") do |s|
      new_source.each do |line|
        s.print(line)
      end
    end
    if file != new_file then
      puts `git rm #{file}`
      puts `git add #{new_file}`
    end
  end
end


