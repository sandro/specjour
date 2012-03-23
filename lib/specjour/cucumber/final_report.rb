module Specjour
  module Cucumber
    class Summarizer
      attr_reader :duration, :failing_scenarios, :step_summary
      def initialize
        @duration = 0.0
        @failing_scenarios = []
        @step_summary = []
        @scenarios = Hash.new(0)
        @steps = Hash.new(0)
      end

      def increment(category, type, count)
        current = instance_variable_get("@#{category}")
        current[type] += count
      end

      def add(stats)
        stats.each do |category, hash|
          if category == :failing_scenarios
            @failing_scenarios += hash
          elsif category == :step_summary
            @step_summary += hash
          elsif category == :duration
            @duration = hash.to_f if duration < hash.to_f
          else
            hash.each do |type, count|
              increment(category, type, count)
            end
          end
        end
      end

      def scenarios(status=nil)
        length = status ? @scenarios[status] : @scenarios.inject(0) {|h,(k,v)| h += v}
        any = @scenarios[status] > 0 if status
        OpenStruct.new(:length => length , :any? => any)
      end

      def steps(status=nil)
        length = status ? @steps[status] : @steps.inject(0) {|h,(k,v)| h += v}
        any = @steps[status] > 0 if status
        OpenStruct.new(:length => length , :any? => any)
      end
    end

    class FinalReport
      include ::Cucumber::Formatter::Console
      def initialize(printer)
        @io = $stdout
        @features = []
        @summarizer = Summarizer.new
        @printer = printer
      end

      def add(stats)
        @summarizer.add(stats)
        notify_failure(stats)
      end

      def notify_failure(stats)
        failures = stats[:failing_scenarios] || []
        failures.each do |failure|
          @printer.did_fail_test(self, failure.file)
        end
      end

      def clear_failure(test)
        @summarizer.failing_scenarios.reject!{ |failure| failure.file == test }
      end

      def exit_status
        @summarizer.failing_scenarios.empty?
      end

      def summarize
        if @summarizer.steps(:failed).any?
          puts "\n\n"
          @summarizer.step_summary.each {|f| puts f }
        end

        if @summarizer.failing_scenarios.any?
          puts "\n\n"
          puts format_string("Failing Scenarios:", :failed)
          @summarizer.failing_scenarios.each do |f|
            puts format_string("cucumber " + f.file, :failed) +
                 format_string(" # Scenario: " + f.name, :comment)
          end
        end

        default_format = lambda {|status_count, status| format_string(status_count, status)}
        puts
        puts scenario_summary(@summarizer, &default_format)
        puts step_summary(@summarizer, &default_format)
        puts format_duration(@summarizer.duration) if @summarizer.duration
      end
    end
  end
end
