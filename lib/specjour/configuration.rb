module Specjour
  module Configuration
    extend self

    attr_writer :before_fork, :after_fork

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

    def reset
      @before_fork = nil
      @after_fork = nil
    end

    def default_before_fork
      lambda do
        ActiveRecord::Base.remove_connection if defined?(ActiveRecord::Base)
      end
    end

    def default_after_fork
      lambda {}
    end
  end
end
