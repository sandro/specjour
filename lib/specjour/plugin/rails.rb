module Specjour::Plugin

  class Rails < Base

    def load_application
      log "Loading rails plugin"
      if File.exists?("./config/application.rb")
        bundle_install
        ENV["RAILS_ENV"] ||= "test"
        require File.expand_path("config/application", Dir.pwd)
        # require File.expand_path("config/environment", Dir.pwd)
        @rails_loaded = true
        Specjour.load_plugins
        if ::Rails.version =~ /^4/
          require "specjour/plugin/rails_v4.rb"
          extend RailsV4
        else
          require "specjour/plugin/rails_v3.rb"
          extend RailsV3
        end
        versioned_load_application
      end
    end

    def before_worker_fork
      return unless @rails_loaded
      ActiveRecord::Base.remove_connection
    end

    protected

    def force_task(task)
      Rake::Task[task].invoke
    rescue StandardError
    end

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
