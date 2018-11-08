#!/usr/bin/ruby

require 'optparse'
require 'ostruct'
require 'tmpdir'

$options = OpenStruct.new

OptionParser.new do |opts|
  opts.banner = "ruby gitdiff.rb [$options]"
  opts.on("-f", "--file FILE", "Source file to run on") do |file|
    $options.source_file = file
  end
  opts.on("-n", "--diff-no N", "Diff to analyse - required if more than one diff") do |n|
    $options.diff_no = n.to_i
  end
  opts.on("-l", "--left", "Show left changes") do 
    $options.diff_to_show = :left
  end
  opts.on("-r", "--right", "Show right changes") do 
    $options.diff_to_show = :right
  end
end.parse!

$options.source_file || (raise "Must provide a source file")
stored_lines = []
storing = false
$lefts = []
$mids = []
$rights = []

IO.readlines($options.source_file).each do |line|
  if line =~ /^<<<</
    storing = true
  elsif line =~ /^\|\|\|\|\|/
    $lefts.push(stored_lines)
    stored_lines = []
  elsif line =~ /^=====/
    $mids.push(stored_lines)
    stored_lines = []
  elsif line =~ /^>>>>>>/
    $rights.push(stored_lines)
    stored_lines = []
    storing = false
  else
    if storing
      stored_lines.push(line)
    end
  end

end

n_diffs = $lefts.size
if $mids.size != n_diffs || $rights.size != n_diffs
  raise "Unmatching diffs (l, m, r) (#{$lefts.size}, #{$mids.size}, #{$rights.size})"
end

$options.diff_no ||= (
  if n_diffs == 1 then 1 else raise "Say which diff you want there are #{n_diffs}" end
)

$options.diff_to_show || (raise "Specify left or right diff")

def write_to_file(lines, f) 
  lines.each do |line|
    f.puts(line)
  end
end

def show_diff
  n = $options.diff_no - 1
  Dir.mktmpdir("GITDIFF") do |dir|
    puts "Dir = #{dir}"
    File.open("#{dir}/l", 'w') do |f|
      write_to_file($lefts[n], f)
    end
    File.open("#{dir}/m", 'w') do |f|
      write_to_file($mids[n], f)
    end
    File.open("#{dir}/r", 'w') do |f|
      write_to_file($rights[n], f)
    end

    if $options.diff_to_show == :left
      puts `diff #{dir}/m #{dir}/l` 
    else
      puts `diff #{dir}/m #{dir}/r` 
    end
  end
end

show_diff





