module Specjour
  module DbScrub
    extend self

    def scrub
      begin
        ActiveRecord::Base.connection
      rescue # assume the database doesn't exist
        create_db_and_schema
      else
        ActiveRecord::Base.connection.tables.each do |table|
          ActiveRecord::Base.connection.delete "delete from #{table}"
        end
      end
    end

    def create_db_and_schema
      load 'Rakefile'
      Rake::Task['db:create'].invoke
      Rake::Task['db:schema:load'].invoke
    end
  end
end
