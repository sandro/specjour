module Specjour
  module Configuration
    extend self

    attr_writer :before_fork, :after_fork, :prepare

    # This block is run by each worker the manager forks.
    # The Rails plugin uses this block to clear the databases defined in
    # ActiveRecord.
    # Set your own block if the default doesn't work for you.
    def after_fork
      @after_fork ||= default_after_fork
    end

    # This block is run after before forking. When ActiveRecord is
    # defined, the default before_block disconnects from the database.
    def before_fork
      @before_fork ||= default_before_fork
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
      @prepare = nil
    end

    def default_before_fork
      lambda do
        ActiveRecord::Base.remove_connection if defined?(ActiveRecord::Base)

        if system('which bundle')
          system('bundle check') || system('bundle install')
        end
      end
    end

    def default_after_fork
      lambda do
        DbScrub.scrub if rails_with_ar?
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

    protected

    def rails_with_ar?
      defined?(Rails) && defined?(ActiveRecord::Base)
    end

    def system(cmd)
      Kernel.system("#{cmd} > /dev/null")
    end
  end
end
