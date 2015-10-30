module Specjour
  require 'rspec/core/formatters/json_formatter'

  class RspecFormatter < ::RSpec::Core::Formatters::JsonFormatter
    def close
      @output_hash[:examples].each do |e|
        @output.report_test(e)
      end
    end
  end
end
