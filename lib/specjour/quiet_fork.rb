module Specjour::QuietFork
  extend self
  attr_reader :pid

  def self.fork(&block)
    @pid = Kernel.fork do
      $stdout = StringIO.new
      block.call
      exit!
    end
  end
end
