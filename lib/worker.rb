#!/usr/bin/env ruby

require 'rinda/ring'
require 'rubygems'
require 'ringy_dingy'
require 'ringy_dingy/ring_server'

class RingyDingy::RingServer
  # monkey patch to add timeout support
  def self.list_services(timeout=5)
    DRb.start_service unless DRb.primary_server

    services = {}

    RF.lookup_ring(timeout) do |ts|
      services[ts.__drburi] = ts.read_all [:name, nil, DRbObject, nil]
    end

    return services
  end
end

class Worker
  include DRbUndumped
  def run(specs)
    puts "running specs #{specs.inspect}"
  end
end

DRb.start_service

if RingyDingy::RingServer.list_services(1).any?
  RingyDingy.new(Worker.new, :SpecjourWorker).run
  # ring_server = Rinda::RingFinger.primary
  # p ring_server
  # p ring_server
  # ring_server.write([:name, :SpecjourWorker, Worker.new, "spec runner"], Rinda::SimpleRenewer.new)

  DRb.thread.join
else
  abort "No ring services found. The master need to run 'ring_server -d' before this worker can should be started"
end
