#!/usr/bin/env ruby
require 'specjour'

raise(ArgumentError, "4 arguments required") and return if ARGV.size < 4
specs_to_run = ARGV[3..-1]
Specjour::Worker.new(ARGV[0], ARGV[1], ARGV[2], specs_to_run).run
