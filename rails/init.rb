if ENV['PREPARE_DB']
  Rails.configuration.after_initialize do
    require 'specjour/db_scrub'
    Specjour::DbScrub.scrub
  end
end
