module Specjour::Plugin
  require 'rake'

  class Rails < Base

    def load_application
      log "Loading rails plugin #{Specjour.configuration.worker_number}"
      if File.exists?("./config/application.rb") && File.exists?("./config/environment.rb")
        bundle_install
        ENV['RAILS_ENV'] = 'test'
        require File.expand_path("config/application", Dir.pwd)
        # require File.expand_path("config/environment", Dir.pwd)
      end
    end

    def before_worker_fork
      # DbScrubber.disconnect_database
    end

    def after_worker_fork
      return unless (defined?(Rails) && defined?(ActiveRecord::Base))
      # DbScrubber.scrub
      ::Rails.application.load_tasks
      ActiveRecord::Base.remove_connection
      force_task('db:drop')
      force_task('db:create')
      Rake::Task[{ :sql  => "db:test:load_structure", :ruby => "db:test:load" }[ActiveRecord::Base.schema_format]].invoke
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.schema_cache.clear!
      ActiveRecord::Base.descendants.each {|m| m.reset_column_information}
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
