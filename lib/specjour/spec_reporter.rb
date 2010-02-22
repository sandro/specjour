module Specjour
  class SpecReporter
    include DRbUndumped
    extend Forwardable

    attr_reader :worker_stdout, :duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples
    def_delegators :worker_stdout, :puts, :print, :flush, :tty?


    def initialize(worker_stdout)
      @worker_stdout = worker_stdout
      @duration = 0.0
      @example_count = 0
      @failure_count = 0
      @pending_count = 0
      @pending_examples = []
      @failing_examples = []
    end

    def add_to_summary(duration, example_count, failure_count, pending_count)
      @duration += duration
      @example_count += example_count
      @failure_count += failure_count
      @pending_count += pending_count
    end

    def add_pending(examples)
      @pending_examples += examples
    end

    def add_failing(example)
      @failing_examples << example
    end

    def to_hash
      h = {}
      [:duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples].each do |key|
        h[key] = send(key)
      end
      h
    end
  end
end
