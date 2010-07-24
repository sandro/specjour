module Specjour::Rspec
  class FinalReport
    attr_reader :examples
    attr_reader :duration

    def initialize
      @examples = []
      @duration = 0.0
    end

    def add(data)
      if data.respond_to?(:has_key?) && data.has_key?(:duration)
        self.duration = data[:duration]
      else
        metadata_for_examples(data)
      end
    end

    def duration=(value)
      @duration = value.to_f if duration < value.to_f
    end

    def exit_status
      formatter.failed_examples.empty?
    end

    def metadata_for_examples(metadata_collection)
      examples.concat(
        metadata_collection.map do |partial_metadata|
          example = ::Rspec::Core::Example.allocate
          metadata = ::Rspec::Core::Metadata.new
          metadata.merge! partial_metadata
          example.instance_variable_set(:@metadata, metadata)
          example
        end
      )
    end

    def formatter
      @formatter ||= new_progress_formatter
    end

    def summarize
      if examples.size > 0
        formatter.dump_summary(duration, formatter.example_count, formatter.failure_count, formatter.pending_count)
        formatter.dump_pending
        formatter.dump_failures
      end
    end

    protected
    def new_progress_formatter
      new_formatter = ::Rspec::Core::Formatters::ProgressFormatter.new($stdout)
      new_formatter.instance_variable_set(:@examples, examples)
      new_formatter.instance_variable_set(:@example_count, examples.size)
      Rspec.configuration.color_enabled = true
      new_formatter
    end
  end
end
