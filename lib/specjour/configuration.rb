module Specjour
  module Configuration
    extend self

    attr_writer :before_fork, :after_fork, :preload_app

    # This block is run by each worker the manager forks.
    # The Rails plugin uses this block to clear the databases defined in
    # ActiveRecord.
    # Set your own block if the default doesn't work for you.
    def after_fork
      @after_fork ||= default_after_fork
    end

    # This block is run after preload but before forking. When ActiveRecord is
    # defined, the default before_block disconnects from the database.
    def before_fork
      @before_fork ||= default_before_fork
    end

    # Preloading the app will require a spec and a feature file into
    # memory, in an effort to load the environment before forking. This saves
    # memory and is optimized to work well with ree.
    # Defaults to true.
    def preload_app?
      @preload_app.nil? ? true : @preload_app
    end

    def reset
      @before_fork = nil
      @after_fork = nil
      @preload_app = nil
    end

    def default_before_fork
      lambda do
        ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
      end
    end

    def default_after_fork
      lambda {}
    end
  end
end
