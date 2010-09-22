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

      require 'specjour/rspec/marshalable_exception'
      require 'specjour/rspec/preloader'
      require 'specjour/rspec2/distributed_formatter'
      require 'specjour/rspec2/final_report'
      require 'specjour/rspec2/runner'
      require 'specjour/rspec2/shared_example_group_ext'
    end

    begin
      load_rspec2
    rescue LoadError
      load_rspec1
    end

  end
end
