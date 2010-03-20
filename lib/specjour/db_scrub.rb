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

    def purge_tables
      tables = ActiveRecord::Base.connection.tables - ['schema_migrations']
      tables.each do |table|
        ActiveRecord::Base.connection.delete "delete from #{table}"
      end
    end

    def pending_migrations?
      ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations.any?
    end
  end
end
