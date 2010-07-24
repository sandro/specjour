module Specjour::Rspec
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

    def noop
    end
    alias dump_pending noop
    alias dump_failures noop
    alias start_dump noop

    def dump_summary(*args)
      output.send_message :rspec_summary=, metadata_for_examples
    end

    protected

    def marshalable_execution_result(execution_result)
      if exception = execution_result[:exception_encountered]
        execution_result[:exception_encountered] = MarshalableException.new(exception)
      end
      execution_result
    end

  end
end
