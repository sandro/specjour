module Specjour
  class DistributedFormatter < Spec::Runner::Formatter::ProgressBarFormatter
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
    end
  end
end
