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
    ])

    DEFAULT_OPTIONS = {
      backtrace_exclusion_pattern: DEFAULT_BACKTRACE_EXCLUSION,
      formatter: Formatter.new,
      full_backtrace: false,
      printer_port: 34276,
      printer_uri: nil,
      project_aliases: [],
      project_name: nil,
      project_path: nil,
      rsync_options: "-aL --delete --ignore-errors",
      rsync_port: 23456,
      test_paths: nil,
      tmp_path: "/tmp",
      worker_size: CPU.cores,
      worker_number: 0
    }

    DEFAULT_OPTIONS.each do |k,v|
      define_method(k) do
        @options[k]
      end

      define_method("#{k}=") do |value|
        @options[k] = value
      end
    end

    def initialize(options={})
      @original_options = options
      @options = DEFAULT_OPTIONS.merge @original_options
    end

  end
end
