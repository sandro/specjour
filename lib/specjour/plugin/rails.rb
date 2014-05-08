module Specjour::Plugin
  class Rails < Base
    include Specjour::Logger

    def load_application
      if File.exists?("./config/application.rb") && File.exists?("./config/environment.rb")
        bundle_install
        require File.expand_path("config/application", Dir.pwd)
        # require File.expand_path("config/environment", Dir.pwd)
      end
    end

    def before_worker_fork
      # DbScrubber.disconnect_database
    end

    def after_worker_fork
      # DbScrubber.scrub
    end

    protected

    def bundle_install
      if system('which bundle')
        system('bundle check') || system('bundle install')
      end
    end

    def system(cmd)
      Kernel.system("#{cmd} > /dev/null")
    end
  end
end
