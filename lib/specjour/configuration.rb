module Specjour
  module Configuration
    extend self

    attr_writer :before_fork, :after_fork, :after_load, :bundler_options, :prepare, :rspec_formatter, :rsync_options

    # This block is run by each worker before they begin running tests.
    # The default action is to migrate the database, and clear it of any old
    # data.
    def after_fork
      @after_fork ||= default_after_fork
    end

    # This block is run after the manager loads the app into memory, but before
    # forking new worker processes. The default action is to disconnect from
    # the ActiveRecord database.
    def after_load
      @after_load ||= default_after_load
    end

    # This block is run by the manager before forking workers. The default
    # action is to run bundle install.
    def before_fork
      @before_fork ||= default_before_fork
    end

    def bundler_options
      @bundler_options ||= ''
    end

    # This block is run on all workers when invoking `specjour prepare`
    # Defaults to dropping the worker's database and recreating it. This
    # is especially useful when two teams are sharing workers and writing
    # migrations at around the same time causing databases to get out of sync.
    def prepare
      @prepare ||= default_prepare
    end

    def reset
      @before_fork = nil
      @after_fork = nil
      @after_load = nil
      @bundler_options = nil
      @prepare = nil
      @rsync_options = nil
      @rspec_formatter = nil
    end

    def rspec_formatter
      @rspec_formatter ||= default_rspec_formatter
    end

    def rsync_options
      @rsync_options ||= default_rsync_options
    end

    def bundle_install
      if system('which bundle')
        system('bundle check') || system(bundle_command)
      end
    end

    def default_before_fork
      lambda do
        bundle_install
      end
    end

    def default_after_fork
      lambda do
        DbScrub.scrub if rails_with_ar?
      end
    end

    def default_after_load
      lambda do
        ActiveRecord::Base.remove_connection if rails_with_ar?
      end
    end

    def default_prepare
      lambda do
        if rails_with_ar?
          DbScrub.drop
          DbScrub.scrub
        end
      end
    end

    def default_rspec_formatter
      lambda do
        ::RSpec::Core::Formatters::ProgressFormatter
      end
    end

    def default_rsync_options
      "-aL --delete --ignore-errors"
    end

    protected

    def bundle_command
      "bundle install #{bundler_options}".strip
    end

    def rails_with_ar?
      defined?(Rails) && defined?(ActiveRecord::Base)
    end

    def system(cmd)
      Kernel.system("#{cmd} > /dev/null")
    end
  end
end
