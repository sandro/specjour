module Specjour
  module Plugin
    class Base
      include SocketHelper
      include Specjour::Logger

      attr_reader :listener, :loader, :worker

      def after_register
      end

      def before_suite
      end

      def after_suite
      end

      def before_loader_fork
      end

      def load_application
      end

      def load_test_suite
      end

      def after_loader_fork
      end

      def before_worker_fork
      end

      def after_worker_fork
        remove_connection
      end

      def interrupted!
      end

      def register_tests_with_printer
      end

      def run_test(test)
        false
      end

      def tests_to_register
        []
      end

      def before_print_summary(formatter)
      end

      def after_print_summary(formatter)
      end

      def exit_status(formatter)
      end

    end
  end
end
