module Specjour
  module Cucumber
    class Printer < ::Specjour::Printer
      def report
        @report ||= FinalReport.new
      end
    end
  end
end
