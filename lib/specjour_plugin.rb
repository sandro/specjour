require "specjour/plugin/rails"
require "specjour/plugin/rspec"

rails_plugin = Specjour::Plugin::Rails.new
rspec_plugin = Specjour::Plugin::RSpec.new

Specjour.plugin_manager.register_plugin rails_plugin
Specjour.plugin_manager.register_plugin rspec_plugin
