module Specjour::Rspec
  class DistributedFormatter < Spec::Runner::Formatter::BaseTextFormatter
    require 'specjour/rspec/marshalable_rspec_failure'

    attr_reader :failing_messages, :passing_messages, :pending_messages, :output
    attr_reader :duration, :example_count, :failure_count, :pending_count, :pending_examples, :failing_examples

    def initialize(options, output)
      @options = options
      @output = output
      @failing_messages = []
      @passing_messages = []
      @pending_messages = []
      @pending_examples = []
      @failing_examples = []
    end

    def example_failed(example, counter, failure)
      failing_messages << colorize_failure('F', failure)
      print_and_flush(failing_messages)
    end

    def example_passed(example)
      passing_messages << green('.')
      print_and_flush(passing_messages)
    end

    def example_pending(example, message, deprecated_pending_location=nil)
      super
      pending_messages << yellow('*')
      print_and_flush(pending_messages)
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
      @duration = duration
      @example_count = example_count
      @failure_count = failure_count
      @pending_count = pending_count
      output.send_message(:rspec_summary=, to_hash)
    end

    def dump_pending
      #noop
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

    def print_and_flush(messages)
      output.print messages.to_s
      output.flush
      messages.replace []
    end
  end
end
