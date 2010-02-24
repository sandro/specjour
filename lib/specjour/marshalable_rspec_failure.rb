module Specjour
  class Spec::Runner::Reporter::Failure
    attr_reader :backtrace, :message, :header, :exception_class_name

    def initialize(group_description, example_description, exception)
      @example_name = "#{group_description} #{example_description}"
      @message = exception.message
      @backtrace = exception.backtrace
      @exception_class_name = exception.class.name
      @pending_fixed = exception.is_a?(Spec::Example::PendingExampleFixedError)
      @exception_not_met = exception.is_a?(Spec::Expectations::ExpectationNotMetError)
      set_header
    end

    def set_header
      if expectation_not_met?
        @header = "'#{@example_name}' FAILED"
      elsif pending_fixed?
        @header = "'#{@example_name}' FIXED"
      else
        @header = "#{exception_class_name} in '#{@example_name}'"
      end
    end

    def pending_fixed?
      @pending_fixed
    end

    def expectation_not_met?
      @exception_not_met
    end
  end
end
