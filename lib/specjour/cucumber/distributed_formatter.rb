module Specjour::Cucumber
  class DistributedFormatter < ::Cucumber::Formatter::Progress
    class << self
      attr_accessor :batch_size
    end
    @batch_size = 1

    def initialize(step_mother, io, options)
      @step_mother = step_mother
      @io = io
      @options = options
    end

    def after_features(features)
      print_summary(features)
    end

    def print_summary(features)
      require 'ruby-debug'; Debugger.start; Debugger.settings[:autoeval] = 1; Debugger.settings[:autolist] = 1; debugger
      @io.send_message(:worker_summary=, features)
    end
  end
end
