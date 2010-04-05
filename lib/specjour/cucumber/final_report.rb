module Specjour
  module Cucumber
    class FinalReport
      def initialize
        @features = []
      end

      def add(features)
        p features
        @features << features
      end

      def summarize
        puts
        puts "this is the summary"
      end
    end
  end
end
