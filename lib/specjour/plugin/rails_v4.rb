module Specjour
  module Plugin
    module RailsV4

      def versioned_load_application
        # require File.expand_path("config/environment", Dir.pwd)
        load "active_record/railties/databases.rake"
        ActiveRecord::Tasks::DatabaseTasks.database_configuration = ::Rails.application.config.database_configuration
        require "rails/tasks"
      end

      def after_worker_fork
        return unless (defined?(::Rails) && defined?(::ActiveRecord::Base))
        ActiveRecord::Tasks::DatabaseTasks.database_configuration = ::Rails.application.config.database_configuration
        ActiveRecord::Base.establish_connection
        force_task('db:drop')
        force_task('db:create')
        Rake::Task[{ :sql  => "db:structure:load", :ruby => "db:schema:load" }[ActiveRecord::Base.schema_format]].invoke
        ActiveRecord::Base.connection.schema_cache.clear!
        ActiveRecord::Base.descendants.each {|m| m.reset_column_information}
      end

    end
  end
end
