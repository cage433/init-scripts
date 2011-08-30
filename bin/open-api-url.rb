#!/usr/bin/ruby -w

$: << File.dirname(__FILE__)
require 'utils'

apis = {"s" => :scala, "j" => :java}
package_files = {:scala => $scala_packages, :java => $java_packages}

require 'utils.rb'

short_name = ARGV[0]
api = apis[ARGV[1]] 
packages = find_packages(short_name, package_files[api])
raise("packages were #{packages}") unless packages.size == 1
package_path=packages[0].sub(".", "/")
url = if api == :java then
            "http://download.oracle.com/javase/6/docs/api/index.html?#{packages[0].sub(".", "/")}/#{short_name}.html"
          else
            "http://www.scala-lang.org/api/current/index.html##{packages[0]}.#{short_name}"
          end
open_url_command = if RUBY_PLATFORM.downcase.include?("linux") then
                     "firefox"
                   else
                     "open"
                   end
#puts "#{open_url_command} #{url}"
result = `#{open_url_command} #{url} 2>&1 > /dev/null`
#puts result




