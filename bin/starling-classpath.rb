#!/usr/bin/ruby -w

jars = `find . -name '*.jar'`.split("\n")
class_dirs = `find . -name classes -type d`.split("\n")
test_class_dirs = `find . -name test-classes -type d`.split("\n")
classpath = (class_dirs + test_class_dirs + jars).join(":")
puts classpath

