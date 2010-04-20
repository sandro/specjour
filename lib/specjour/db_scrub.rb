module Specjour
  module DbScrub
    load 'Rakefile'
    extend self

    def scrub
      connect_to_database
      if pending_migrations?
        puts "Migrating schema for database #{ENV['TEST_ENV_NUMBER']}..."
        Rake::Task['db:test:load'].invoke
      else
        purge_tables
      end
    end

    protected

    def connect_to_database
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

    def tables_to_purge
      connection.tables - ['schema_migrations']
    end
  end
end
