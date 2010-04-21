module Specjour
  module Rspec
    class ::Spec::Runner::Reporter::Failure

      def initialize(group_description, example_description, exception)
        @example_name = "#{group_description} #{example_description}"
        @exception = MarshalableException.new(exception)
        @pending_fixed = exception.is_a?(Spec::Example::PendingExampleFixedError)
        @exception_not_met = exception.is_a?(Spec::Expectations::ExpectationNotMetError)
      end

      def pending_fixed?
        @pending_fixed
      end

      def expectation_not_met?
        @exception_not_met
      end
    end
  end

  class MarshalableException
    attr_accessor :message, :backtrace, :class_name

    def initialize(exception)
      self.class_name = exception.class.name
      self.message = exception.message
      self.backtrace = exception.backtrace
    end

    def class
      @class ||= OpenStruct.new :name => class_name
    end
  end
end
