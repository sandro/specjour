#!/usr/bin/env ruby

require 'drb'
require 'uri'
require 'open3'
require 'rubygems'
require 'dnssd'

class Worker
  include DRbUndumped
  def run(specs)
    puts "running specs #{specs.inspect}"
    sleep (rand * 10).to_i
    puts "done"
    # rand > 0.5
    # Open3.popen3('cd ~/src/ruby/assembly_line/ && spec --color spec') do |stdin, stdout, stderr|

      # stdout.read
    # end
  end
end

DRb.start_service nil, Worker.new
puts "DRB server running at #{DRb.uri}"

uri = URI.parse(DRb.uri)
DNSSD.register 'specjour_worker', "_#{uri.scheme}._tcp", nil, uri.port

trap("INT") { DRb.stop_service }

DRb.thread.join
