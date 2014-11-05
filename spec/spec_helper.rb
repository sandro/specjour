$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'specjour'
require 'rspec/autorun'
require 'rr'
require 'fakefs/spec_helpers'

class NullObject
  def method_missing(name, *args)
    self
  end
end

RSpec.configure do |config|
  config.mock_with :rr
end
