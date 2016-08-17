module Specjour::Plugin
  require 'rake'

  class Rails < Base

    def load_application
      log "Loading rails plugin"
      if File.exists?("./config/application.rb") && File.exists?("./config/environment.rb")
        @rails_loaded = true
        bundle_install
        ENV["RAILS_ENV"] ||= "test"
        require File.expand_path("config/application", Dir.pwd)
        load "active_record/railties/databases.rake"
        Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
        Specjour.load_plugins
        # require File.expand_path("config/environment", Dir.pwd)
      end
    end

    def before_worker_fork
      return unless @rails_loaded
      # DbScrubber.disconnect_database
      ActiveRecord::Base.remove_connection
    end

    def after_worker_fork
      return unless (defined?(::Rails) && defined?(::ActiveRecord::Base))
      # DbScrubber.scrub
      # ::Rails.application.load_tasks
      force_task('db:drop')
      force_task('db:create')
      Rake::Task[{ :sql  => "db:test:load_structure", :ruby => "db:test:load" }[ActiveRecord::Base.schema_format]].invoke
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.schema_cache.clear!
      ActiveRecord::Base.descendants.each {|m| m.reset_column_information}
      # require File.expand_path("config/environment", Dir.pwd)
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
