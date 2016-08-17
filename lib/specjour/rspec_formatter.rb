module Specjour
  require 'rspec/core/formatters/json_formatter'

  class RspecFormatter < ::RSpec::Core::Formatters::JsonFormatter
    def hostname
      @hostname ||= Socket.gethostname
    end

    def close
      @output_hash[:examples].each do |e|
        e["hostname"] = hostname
        e["worker_number"] = ENV["TEST_ENV_NUMBER"]
        @output.report_test(e)
      end
    end
  end
end
