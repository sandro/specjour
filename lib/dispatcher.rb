#!/usr/bin/env ruby

require 'drb'
require 'uri'
require 'rubygems'
require 'dnssd'

workers = []

browser = DNSSD::Service.new
browser.browse '_druby._tcp' do |reply|
  DNSSD.resolve(reply) do |r|
    uri = URI::Generic.build :scheme => reply.service_name, :host => r.target, :port => r.port
    workers << DRbObject.new_with_uri(uri.to_s)
    reply.service.stop
  end
end
p workers

threads = []
workers.each do |worker|
  threads << Thread.new do
    puts worker.run("spec/1 spec/2 spec/3")
  end
end

threads.each {|t| t.join}
