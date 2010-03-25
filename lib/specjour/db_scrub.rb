module Specjour
  module DbScrub
    extend self

    def scrub
      load 'Rakefile'
      begin
        ActiveRecord::Base.connection
      rescue # assume the database doesn't exist
        Rake::Task['db:create'].invoke
        Rake::Task['db:schema:load'].invoke
      else
        if pending_migrations?
          Rake::Task['db:migrate'].invoke
        end

        purge_tables
      end
    end

    protected

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
