# encoding: utf-8
module Specjour
  module DbScrub

    begin
      require 'rake'
      extend Rake::DSL if defined?(Rake::DSL)
      if defined?(Rails)
        Rake::Task.define_task(:environment) { }
        load 'rails/tasks/misc.rake'
        load 'active_record/railties/databases.rake'
      end
    rescue LoadError
      Specjour.logger.debug "Failed to load Rails rake tasks"
    end

    extend self

    def drop
      Rake::Task['db:drop'].invoke
    end

    def scrub
      connect_to_database
      puts "Resetting database #{ENV['TEST_ENV_NUMBER']}"
      schema_load_task.invoke
    end

    protected

    def connect_to_database
      ActiveRecord::Base.remove_connection
      ActiveRecord::Base.configurations = Rails.application.config.database_configuration
      ActiveRecord::Tasks::DatabaseTasks.db_dir = Rails.root.join('db')
      ActiveRecord::Base.establish_connection ActiveRecord::Base.configurations['test']
      connection
    rescue # assume the database doesn't exist
      Rake::Task['db:create'].invoke
    end

    def connection
      ActiveRecord::Base.connection
    end

    def pending_migrations?
      ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations.any?
    end

    def schema_load_task
      case ActiveRecord::Base.schema_format
        when :sql
          Rake::Task['db:test:load_structure']
        when :ruby
          Rake::Task['db:schema:load']
      end
    end

    def tables_to_purge
      connection.tables - ['schema_migrations']
    end
  end
end
