module Specjour
  module Rspec
    def self.load_rspec1
      require 'spec'
      require 'spec/runner/formatter/base_text_formatter'

      require 'specjour/rspec/distributed_formatter'
      require 'specjour/rspec/final_report'
      require 'specjour/rspec/marshalable_exception'
      require 'specjour/rspec/preloader'
      require 'specjour/rspec/runner'
    end

    def self.load_rspec2
      require 'rspec/core'
      require 'rspec/core/formatters/progress_formatter'

      require 'specjour/rspec/marshalable_exception'
      require 'specjour/rspec/preloader'
      require 'specjour/rspec2/distributed_formatter'
      require 'specjour/rspec2/final_report'
      require 'specjour/rspec2/runner'
      require 'specjour/rspec2/shared_example_group_ext'

      ::RSpec::Core::Runner.disable_autorun!
    end

    begin
      load_rspec2
    rescue LoadError
      load_rspec1
    end

    def self.wants_to_quit
      if defined?(::RSpec) && ::RSpec.respond_to?(:wants_to_quit=)
        ::RSpec.wants_to_quit = true
      end
    end
  end
end
