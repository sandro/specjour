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
      @io.send_message(:worker_summary=, to_hash)
    end

    OUTCOMES = [:failed, :skipped, :undefined, :pending, :passed]

    def to_hash
      hash = {}
      [:scenarios, :steps].each do |type|
        hash[type] = {}
        OUTCOMES.each do |outcome|
          hash[type][outcome] = step_mother.send(type, outcome).size
        end
      end
      hash
    end

  end
end
