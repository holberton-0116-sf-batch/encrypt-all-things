#!/usr/bin/ruby -w
require 'digest/sha1'
# Ruby script encrypts string with SHA1
ARGV.each do|a|
  puts Digest::SHA1.hexdigest "#{a}"
end
