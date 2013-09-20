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
      begin
        Rake::Task['db:drop'].invoke
      rescue
        raise "Failed to drop database #{ENV['TEST_ENV_NUMBER']}"
      end
    end

    def scrub
      connect_to_database
      puts "Resetting database #{ENV['TEST_ENV_NUMBER']}"
      begin
        schema_load_task.invoke
      rescue
        raise "Failed to invoke task in worker #{ENV['TEST_ENV_NUMBER']}"
      end
    end

    protected

    def connect_to_database
      ActiveRecord::Base.remove_connection
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
      Rake::Task['db:schema:load'].invoke if ActiveRecord::Base.schema_format == :ruby
      Rake::Task['db:structure:load'].invoke if ActiveRecord::Base.schema_format == :sql
    end

    def tables_to_purge
      connection.tables - ['schema_migrations']
    end
  end
end
