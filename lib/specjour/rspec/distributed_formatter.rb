module Specjour::RSpec
  class DistributedFormatter < ::RSpec::Core::Formatters::ProgressFormatter

    def metadata_for_examples
      examples.map do |example|
        metadata = example.metadata
        {
          :execution_result => marshalable_execution_result(example.execution_result),
          :description      => metadata[:description],
          :file_path        => metadata[:file_path],
          :full_description => metadata[:full_description],
          :line_number      => metadata[:line_number],
          :location         => metadata[:location]
        }
      end
    end

    def noop(*args)
    end
    alias dump_pending noop
    alias dump_failures noop
    alias start_dump noop
    alias message noop

    def color_enabled?
      true
    end

    def dump_summary(*args)
      output.send_message :rspec_summary=, metadata_for_examples
    end

    def close
      examples.clear
      super
    end

    protected

    def marshalable_execution_result(execution_result)
      if exception = execution_result[:exception]
        execution_result[:exception] = MarshalableException.new(exception)
      end
      execution_result
    end

  end
end
