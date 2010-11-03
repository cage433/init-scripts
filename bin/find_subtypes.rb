#!/usr/bin/ruby -w

$short_name = ARGV[0]

$subtypes = []

def add_subtypes(file)
  regexp = /^#{$short_name}\s+((\w|,)+)/
  IO.readlines(file).each do |line|
    if line =~ regexp
      $subtypes += $1.split(",")
    end
  end
end
add_subtypes("#{ENV['HOME']}/starling/starling_super_to_sub")

puts $subtypes.uniq
