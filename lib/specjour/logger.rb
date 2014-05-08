module Specjour
  module Logger
    def log(msg)
      Specjour.logger.debug msg
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
