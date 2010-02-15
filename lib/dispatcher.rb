#!/usr/bin/env ruby

require 'drb/drb'
require 'rinda/ring'
require 'rinda/tuplespace'

DRb.start_service

ring_server = Rinda::RingFinger.primary
#
# service = ring_server.read([:name, nil, nil, nil])

# worker = service[2]
# worker.run("spec/1 spec/2 spec/3")

services = ring_server.read_all([:name, nil, nil, nil])
services.each do |service|
  worker = service[2]
  worker.run("spec/1 spec/2 spec/3")
end
  # p service
  # worker = service[2]
  # worker.run("spec/1 spec/2 spec/3")
# end
