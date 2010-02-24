module Specjour
  class DistributedFormatter < Spec::Runner::Formatter::BaseTextFormatter
    BATCH = 1

    attr_reader :failing_messages, :passing_messages, :pending_messages

    def initialize(options, output)
      @failing_messages = []
      @passing_messages = []
      @pending_messages = []
      super
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

    def dump_summary(*args)
      @output.add_to_summary(*args)
    end

    def dump_pending
      @output.add_pending(@pending_examples) if @pending_examples.any?
    end

    def dump_failure(counter, failure)
      @output.add_failing failure
    end

    def start_dump
      print_and_flush failing_messages
      print_and_flush passing_messages
      print_and_flush pending_messages
    end

    protected

    def batch_print(messages)
      if messages.size == BATCH
        print_and_flush(messages)
      end
    end

    def print_and_flush(messages)
      @output.print messages.join('')
      @output.flush
      messages.clear
    end
  end
end
