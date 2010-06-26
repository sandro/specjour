module Specjour::PipeFork
  extend self
  attr_reader :pid, :stdin, :stdout

  def self.fork(&block)
    @stdin, @stdout = IO.pipe
    @pid = Kernel.fork do
      $stdin.reopen stdin
      $stdout.reopen stdout
      block.call
    end
  end
end
