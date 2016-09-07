module Specjour
  class Configuration
    attr_accessor :options

    DEFAULT_BACKTRACE_EXCLUSION = Regexp.union([
      "/lib/specjour/",
      /lib\/rspec\/(core|expectations|matchers|mocks)/,
      "/gems/",
      "spec/spec_helper.rb",
      "spec/rails_helper.rb",
      "bin/"
    ]).freeze

    DEFAULT_OPTIONS = {
      backtrace_exclusion_pattern: DEFAULT_BACKTRACE_EXCLUSION,
      formatter: Formatter.new,
      full_backtrace: false,
      printer_port: 334422,
      printer_uri: nil,
      project_aliases: [],
      project_name: nil,
      project_path: nil,
      remote_job: nil,
      rsync_options: "-aL --delete --ignore-errors",
      rsync_port: 23456,
      test_paths: nil,
      tmp_path: "/tmp",
      worker_size: lambda { Specjour.configuration.remote_job ? CPU.half_cores : CPU.cores },
      worker_number: 0
    }.freeze

    def self.make_option(name)
      define_method(name) do
        option = @options[name]
        if option.respond_to?(:call)
          option.call()
        else
          option
        end
      end

      define_method("#{name}=") do |value|
        @options[name] = value
      end
    end

    DEFAULT_OPTIONS.each do |k,v|
      make_option(k)
    end

    def initialize(options={})
      @original_options = options
      set_options
    end

    def set_options
      @options = DEFAULT_OPTIONS.merge @original_options
    end

  end
end
