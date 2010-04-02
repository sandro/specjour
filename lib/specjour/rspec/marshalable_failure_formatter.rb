module Specjour::Rspec
  class MarshalableFailureFormatter < Spec::Runner::Formatter::BaseTextFormatter
    def dump_failure(counter, failure)
      @output.puts
      @output.puts "#{counter.to_s})"
      @output.puts colorize_failure("#{failure.header}\n#{failure.message}", failure)
      @output.puts format_backtrace(failure.backtrace)
      @output.flush
    end
  end
end
