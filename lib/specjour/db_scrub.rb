module Specjour
  module DbScrub
    require 'rake'
    if defined?(Rails) && Rails.version =~ /^3/
      task(:environment) {}
      load 'rails/tasks/misc.rake'
      load 'active_record/railties/databases.rake'
    else
      load 'tasks/misc.rake'
      load 'tasks/databases.rake'
      Rake::Task["db:structure:dump"].clear
    end

    extend self

    def drop
      Rake::Task['db:drop'].invoke
    end

    def scrub
      connect_to_database
      if pending_migrations?
        puts "Migrating schema for database #{ENV['TEST_ENV_NUMBER']}..."
        schema_load_task.invoke
      else
        purge_tables
      end
    end

    protected

    def connect_to_database
      ActiveRecord::Base.remove_connection
      connection
    rescue # assume the database doesn't exist
      Rake::Task['db:create'].invoke
    end

    def connection
      ActiveRecord::Base.connection
    end

    def purge_tables
      connection.disable_referential_integrity do
        tables_to_purge.each do |table|
          connection.delete "delete from #{table}"
        end
      end
    end

    def pending_migrations?
      ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations.any?
    end

    def schema_load_task
      Rake::Task[{ :sql  => "db:test:clone_structure", :ruby => "db:test:load" }[ActiveRecord::Base.schema_format]]
    end

    def tables_to_purge
      connection.tables - ['schema_migrations']
    end
  end
end
