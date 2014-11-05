module Specjour
  module Plugin
    class Base
      include SocketHelper
      include Specjour::Logger

      attr_reader :listener, :loader, :worker

      def before_suite
      end

      def after_suite
      end

      def before_loader_fork
      end

      def load_application
      end

      def after_loader_fork
      end

      def before_worker_fork
      end

      def after_worker_fork
        remove_connection
      end

      def interrupted!
        Process.kill "INT", Process.pid
      end

      def register_tests_with_printer
      end

      def run_test(test)
        false
      end

      def tests_to_register
        []
      end
    end
  end
end
