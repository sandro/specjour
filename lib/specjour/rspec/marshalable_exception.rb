module Specjour::Rspec
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
