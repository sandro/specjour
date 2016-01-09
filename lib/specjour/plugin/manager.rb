module Specjour::Plugin
  class Manager
    include Specjour::Logger
    attr_reader :plugins

    def initialize
      @plugins = []
    end

    def register_plugin(plugin, position=-1)
      if !plugins.include?(plugin)
        plugins.insert(position, plugin)
      end
    end

    def clear_plugins
      plugins.clear
    end

    def send_task(task, *args)
      plugins.each do |plugin|
        log "sending task to plugin: #{task}, #{plugin}"
        plugin.__send__(task, *args)
        # break if plugin.__send__(task, *args) == false
      end
    end
  end
end
