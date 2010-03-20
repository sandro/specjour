if ENV['PREPARE_DB']
  require 'specjour/db_scrub'
  Specjour::DbScrub.scrub
end
