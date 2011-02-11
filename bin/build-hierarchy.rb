#!/usr/bin/ruby -w

require 'find'

super_to_sub = {}
sub_to_super = {}

def add_to_map(map, k, v)
  if map[k] then
    map[k] = map[k].unshift(v)
  else
    map[k] = [v]
  end
end
Find.find("#{ENV['HOME']}/starling") do |file|
  if file =~ /\.scala$/ then
    file_text = IO.readlines(file, nil)[0]
    file_text.scan(/class\s+([A-Z]\w*)([^{]*)\{/).each do |match|
      sub_class = match[0]
      match[1].scan(/((extends)|(with))\s+([A-Z]\w*)/).each do |submatch|
        super_class = submatch[3]
        add_to_map(super_to_sub, super_class, sub_class)
        add_to_map(sub_to_super, sub_class, super_class)
      end
    end
  end
end
def write_map_to_file(file, map)
  File.open("#{ENV['HOME']}/starling/" + file, "w") do |f|
    map.each { |k, v|
      f.puts "#{k}\t#{v.uniq.join(",")}"
    }
  end
end
write_map_to_file("starling_super_to_sub", super_to_sub)
write_map_to_file("starling_sub_to_super", sub_to_super)
      



