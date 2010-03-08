module Specjour
  class MarshaledOut
    extend Forwardable
    attr_reader :output
    def_delegators :output, :flush, :tty?

    def initialize(output)
      @output = output
    end

    def puts(arg)
      output.print(Marshal.dump(arg << "\n") << Specjour::TERMINATOR)
    end

    def print(arg)
      output.print(Marshal.dump(arg) << Specjour::TERMINATOR)
    end
  end

  class DistributedFormatter < Spec::Runner::Formatter::BaseTextFormatter
    class << self
      attr_accessor :batch_size
    end
    @batch_size = 1

    attr_reader :failing_messages, :passing_messages, :pending_messages, :output
    attr_reader :duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples

    def initialize(options, output)
      @options = options
      @output = MarshaledOut.new output
      @failing_messages = []
      @passing_messages = []
      @pending_messages = []
      @pending_examples = []
      @failing_examples = []
    end

    def example_failed(example, counter, failure)
      failing_messages << colorize_failure('F', failure)
      batch_print(failing_messages)
    end

    def example_passed(example)
      passing_messages << green('.')
      batch_print(passing_messages)
    end

    def example_pending(example, message, deprecated_pending_location=nil)
      super
      pending_messages << yellow('*')
      batch_print(pending_messages)
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
      @duration = duration
      @example_count = example_count
      @failure_count = failure_count
      @pending_count = pending_count
      output.puts [:worker_summary=, to_hash]
      output.flush
    end

    def dump_pending
    end

    def dump_failure(counter, failure)
      failing_examples << failure
    end

    def start_dump
      print_and_flush failing_messages
      print_and_flush passing_messages
      print_and_flush pending_messages
    end

    def to_hash
      h = {}
      [:duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples].each do |key|
        h[key] = send(key)
      end
      h
    end

    protected

    def batch_print(messages)
      if messages.size == self.class.batch_size
        print_and_flush(messages)
      end
    end

    def print_and_flush(messages)
      output.print messages.to_s
      output.flush
      messages.replace []
    end
  end
end
