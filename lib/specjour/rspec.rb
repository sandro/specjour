module Specjour
  module Rspec
    require 'spec'
    require 'spec/runner/formatter/base_text_formatter'

    require 'specjour/rspec/distributed_formatter'
    require 'specjour/rspec/final_report'
    require 'specjour/rspec/marshalable_failure_formatter'
  end
end
