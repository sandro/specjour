module Specjour::RSpec
  class FinalReport
    attr_reader :examples
    attr_reader :duration

    def initialize
      @examples = []
      @duration = 0.0
      ::RSpec.configuration.color_enabled = true
      ::RSpec.configuration.output_stream = $stdout
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
          example = ::RSpec::Core::Example.allocate
          example.instance_variable_set(:@example_group_class,
            OpenStruct.new(:metadata => {}, :ancestors => [])
          )
          metadata = ::RSpec::Core::Metadata.new
          metadata.merge! partial_metadata
          example.instance_variable_set(:@metadata, metadata)
          example
        end
      )
    end

    def pending_examples
      examples.select { |e| e.metadata.any_apply?(:execution_result => {:status => 'pending'}) }
    end

    def failed_examples
      examples.select { |e| e.metadata.any_apply?(:execution_result => {:status => 'failed'}) }
    end

    def formatter
      @formatter ||= new_progress_formatter
    end

    def summarize
      if examples.size > 0
        formatter.start_dump
        formatter.dump_pending
        formatter.dump_failures
        formatter.dump_summary(duration, examples.size, failed_examples.size, pending_examples.size)
      end
    end

    protected
    def new_progress_formatter
      new_formatter = ::RSpec::Core::Formatters::ProgressFormatter.new($stdout)
      new_formatter.instance_variable_set(:@failed_examples, failed_examples)
      new_formatter.instance_variable_set(:@pending_examples, pending_examples)
      new_formatter
    end
  end
end
