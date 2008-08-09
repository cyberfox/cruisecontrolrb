#!/usr/bin/env ruby -w

require 'rubygems'
require 'beanstalk-client'

server, queue = $*

puts "Server:  #{server}, queue: #{queue}"

q=Beanstalk::Pool.new([server], queue)
q.put('')
q.close