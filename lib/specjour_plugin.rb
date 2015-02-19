require "specjour/plugin/rails"
require "specjour/plugin/rspec"

Specjour.plugin_manager.register_plugin Specjour::Plugin::Rails.new
Specjour.plugin_manager.register_plugin Specjour::Plugin::RSpec.new
