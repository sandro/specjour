module Specjour
  module RSpec
    require 'rspec/core'
    require 'rspec/core/formatters/progress_formatter'

    require 'specjour/rspec/marshalable_exception'
    require 'specjour/rspec/preloader'
    require 'specjour/rspec/distributed_formatter'
    require 'specjour/rspec/final_report'
    require 'specjour/rspec/runner'
    require 'specjour/rspec/shared_example_group_ext'

    ::RSpec::Core::Runner.disable_autorun!
    ::RSpec::Core::Runner.class_eval "def self.trap_interrupt;end"
  end
end
