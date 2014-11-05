module Specjour
  module Plugin
    class SSH < Base
      def initialize

      end

      def after_loader_fork
        # hosts.each do |host|
        #   host.connect
        #   host.rsync
        #   host.load_plugins
        #   host.load_application
        #   host.launch_workers
        #   host.proxy_tests!
        # end
        #
        # ssh host specjour launch an ssh loader
        # specjour loader -h localhost:2000
        #
      end
    end
  end
end
