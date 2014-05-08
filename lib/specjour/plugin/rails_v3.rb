module Specjour
  module Plugin
    module RailsV3

      def versioned_load_application
        load "active_record/railties/databases.rake"
        Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
        Rake::Task.define_task(:rails_env) unless Rake::Task.task_defined?(:rails_env)
      end

      def after_worker_fork
        return unless (defined?(::Rails) && defined?(::ActiveRecord::Base))
        force_task('db:drop')
        force_task('db:create')
        Rake::Task[{ :sql  => "db:test:load_structure", :ruby => "db:test:load" }[ActiveRecord::Base.schema_format]].invoke
        ActiveRecord::Base.establish_connection
        ActiveRecord::Base.connection.schema_cache.clear!
        ActiveRecord::Base.descendants.each {|m| m.reset_column_information}
      end

    end
  end
end
