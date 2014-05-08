# encoding: utf-8
module Specjour
  class DbScrubber
    include Logger

    def initialize
      load_tasks
    end

    def disconnect_database
      ActiveRecord::Base.remove_connection
    end

    def drop
      Rake::Task['db:drop'].invoke
    end

    def load_tasks
      Rails.application.load_tasks
    end

    def scrub
      connect_to_database
      puts "Resetting database #{ENV['TEST_ENV_NUMBER']}"
      schema_load_task.invoke
    end

    protected

    def connect_to_database
      disconnect_database
      ActiveRecord::Base.configurations = Rails.application.config.database_configuration
      ActiveRecord::Base.establish_connection
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
      Rake::Task[{ :sql  => "db:test:load_structure", :ruby => "db:test:load" }[ActiveRecord::Base.schema_format]]
    end

    def tables_to_purge
      connection.tables - ['schema_migrations']
    end
  end
end
