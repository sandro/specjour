module Specjour
  module Logger

    def log(msg)
      Specjour.logger.info(self.class.name) { format(msg) }
    end

    def debug(msg)
      Specjour.logger.debug(self.class.name) { format("#{msg}\n\t#{called_from}") }
    end

    private

    def format(msg)
      prefix = Specjour.configuration.worker_number > 0 ? "[#{Specjour.configuration.worker_number}] " : ""
      "#{prefix}#{msg}"
    end

    def called_from
      caller.detect {|s| s =~ /specjour\/lib\/specjour\/(?!logger\.rb)/}
    end

    # def self.extended(base)
    #   base.instance_methods.each do |instance_method|
    #     define_method instance_method do |*args|
    #       log __method__
    #       val = super *args
    #       log val
    #       val
    #     end
    #   end
    # end
  end
end
