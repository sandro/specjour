module Specjour
  module Rspec
    require 'spec'
    require 'spec/runner/formatter/base_text_formatter'

    autoload :DistributedFormatter, 'specjour/rspec/distributed_formatter'
    autoload :FinalReport, 'specjour/rspec/final_report'
    autoload :MarshalableFailureFormatter, 'specjour/rspec/marshalable_failure_formatter'
  end
end
