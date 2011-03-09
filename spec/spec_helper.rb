$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'specjour'

class NullObject
  def method_missing(name, *args)
    self
  end
end

begin
  Specjour::DbScrub
rescue LoadError
  $stderr.puts "DbScrub failed to load properly, that's okay though"
end

RSpec.configure do |config|
  config.mock_with :rr
end
