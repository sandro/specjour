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
      @failing_scenarios = []
    end

    def after_features(features)
      print_summary
      step_mother.scenarios.clear
      step_mother.steps.clear
    end

    def prepare_failures
      @failures = step_mother.scenarios(:failed).select { |s| s.is_a?(Cucumber::Ast::Scenario) }

      if !@failures.empty?
        @failures.each do |failure|
          failure_message = ''
          failure_message += format_string("cucumber " + failure.file_colon_line, :failed) +
          failure_message += format_string(" # Scenario: " + failure.name, :comment)
          @failing_scenarios << failure_message
        end
      end
    end

    def print_summary
      prepare_failures

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
      hash.merge!(:failing_scenarios => @failing_scenarios)
      hash
    end

  end
end
