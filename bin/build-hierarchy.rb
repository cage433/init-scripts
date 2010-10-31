#/usr/bin/ruby -w

require 'find'

Find.find("#{ENV['HOME']}/starling") do |file|
  if file =~ /\.scala$/ then
    file_text = IO.readlines(file, nil)


