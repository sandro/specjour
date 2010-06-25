Specjour::Configuration.after_fork = lambda do
  require 'specjour/db_scrub'
  Specjour::DbScrub.scrub
end
