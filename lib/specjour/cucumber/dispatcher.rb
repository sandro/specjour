module Specjour
  module Cucumber
    class Dispatcher < ::Specjour::Dispatcher

      protected

      def all_specs
        @all_specs ||= Dir.chdir(project_path) do
          Dir["features/**/*.feature"]
        end
      end

      def printer
        @printer ||= Printer.new.start
      end
    end
  end
end
