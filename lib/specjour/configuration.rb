module Specjour
  class Configuration
    attr_accessor :options

    def default_options
      {
        printer_port: 34276,
        printer_uri: nil,
        project_name: nil,
        project_path: nil,
        rsync_options: "-aL --delete --ignore-errors",
        rsync_port: 23456,
        test_paths: nil,
        worker_size: CPU.cores,
        worker_size: 1
      }
    end

    def initialize(options={})
      @original_options = options
      @options = default_options.merge options
    end

    # This block is run by each worker before they begin running tests.
    # The default action is to migrate the database, and clear it of any old
    # data.
    def after_fork
      DbScrubber.scrub
    end

    # This block is run after the manager loads the app into memory, but before
    # forking new worker processes. The default action is to disconnect from
    # the ActiveRecord database.
    def after_load
      DbScrubber.disconnect_database
    end

    # This block is run by the manager before forking workers. The default
    # action is to run bundle install.
    def before_fork
      bundle_install
    end

    def formatter
      options[:formatter]
    end

    def load_application
      if File.exists?("./config/application.rb") && File.exists?("./config/environment.rb")
        require File.expand_path("config/application", Dir.pwd)
        # require File.expand_path("config/environment", Dir.pwd)
      else
        require File.expand_path("spec/spec_helper", Dir.pwd)
      end
    end

    # This block is run on all workers when invoking `specjour prepare`
    # Defaults to dropping the worker's database and recreating it. This
    # is especially useful when two teams are sharing workers and writing
    # migrations at around the same time causing databases to get out of sync.
    def prepare
      if rails_with_ar?
        DbScrubber.drop
        DbScrubber.scrub
      end
    end

    def printer_port
      options[:printer_port]
    end

    def printer_uri
      options[:printer_uri]
    end

    def project_name
      options[:project_name]
    end

    def rsync_options
      options[:rsync_options]
    end

    def rsync_port
      options[:rsync_port]
    end

    def test_paths
      options[:test_paths]
    end

    def worker_size
      options[:worker_size]
    end

    protected

    def bundle_install
      if system('which bundle')
        system('bundle check') || system('bundle install')
      end
    end

    def rails_with_ar?
      defined?(Rails) && defined?(ActiveRecord::Base)
    end

    def system(cmd)
      Kernel.system("#{cmd} > /dev/null")
    end
  end
end
  # module Configuration
  #   extend self



  #   def reset
  #     @before_fork = nil
  #     @after_fork = nil
  #     @after_load = nil
  #     @prepare = nil
  #     @printer_port = nil
  #     @rsync_options = nil
  #     @rspec_formatter = nil
  #   end

  # end
# end
