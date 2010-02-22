module Specjour
  class FinalReport
    attr_reader :duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples

    def initialize
      @duration = 0.0
      @example_count = 0
      @failure_count = 0
      @pending_count = 0
      @pending_examples = []
      @failing_examples = []
    end

    def add(stats)
      stats.each do |key, value|
        current = send(key)
        instance_variable_set("@#{key}", current + value)
      end
    end

    def formatter_options
      @formatter_options ||= OpenStruct.new(
        :colour   => true,
        :autospec => false,
        :dry_run  => false
      )
    end

    def formatter
      @formatter ||= begin
        f = Spec::Runner::Formatter::BaseTextFormatter.new(formatter_options, $stdout)
        f.instance_variable_set(:@pending_examples, pending_examples)
        f
      end
    end

    def summarize
      if example_count > 0
        formatter.dump_pending
        dump_failures
        formatter.dump_summary(duration, example_count, failure_count, pending_count)
      end
    end

    def dump_failures
      failing_examples.each_with_index do |failure, index|
        formatter.dump_failure index + 1, failure
      end
    end
  end
end
