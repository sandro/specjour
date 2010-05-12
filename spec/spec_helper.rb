$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'specjour'
require 'spec/autorun'

class NullObject
  def method_missing(name, *args)
    self
  end
end

Spec::Runner.configure do |config|
  config.mock_with :rr
end
