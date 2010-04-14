module Specjour
  module Cucumber
    class Summarizer
      def initialize
        @scenarios = Hash.new(0)
        @steps = Hash.new(0)
      end

      def increment(category, type, value)
        current = instance_variable_get("@#{category}")
        current[type] += value
      end

      def add(stats)
        stats.each do |category, hash|
          hash.each do |type, count|
            increment(category, type, value)
          end
        end
      end

      def scenarios(status=nil)
        require 'ostruct'
        OpenStruct.new(:length => status ? @scenarios[status] : @scenarios.inject(0) {|h,(k,v)| h += v})
      end
    end

    class FinalReport
      include ::Cucumber::Formatter::Summary
      def initialize
        @features = []
        @summarizer = Summarizer.new
      end

      def add(stats)
        @summarizer.add(stats)
      end

      def summarize
        puts "\n\nTIM SAYS HI\n\n"
        puts "sum: #{@summarizer.scenarios}"
        puts scenario_summary(@summarizer) {|status_count, status| "#{status_count} #{status}"}
        puts step_summary(@summarizer)
        puts "\n\nTIM SAYS BYE\n\n"
      end
    end
  end
end
