module Specjour
  module Cucumber
    class Summarizer
      attr_reader :duration, :failing_scenarios
      def initialize
        @duration = 0.0
        @failing_scenarios = []
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
        require 'ostruct'
        length = status ? @scenarios[status] : @scenarios.inject(0) {|h,(k,v)| h += v}
        any = @scenarios[status] > 0 if status
        OpenStruct.new(:length => length , :any? => any)
      end

      def steps(status=nil)
        require 'ostruct'
        length = status ? @steps[status] : @steps.inject(0) {|h,(k,v)| h += v}
        any = @steps[status] > 0 if status
        OpenStruct.new(:length => length , :any? => any)
      end
    end

    class FinalReport
      include ::Cucumber::Formatter::Console
      def initialize
        @features = []
        @summarizer = Summarizer.new
      end

      def add(stats)
        @summarizer.add(stats)
      end

      def summarize
        if @summarizer.failing_scenarios.any?
          puts
          puts
          puts format_string("Failing Scenarios:", :failed)
          @summarizer.failing_scenarios.each {|f| puts f }
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
