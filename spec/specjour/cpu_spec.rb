require 'spec_helper'

describe Specjour::CPU do
  context "on a Mac" do
    let(:hostinfo) do
      %(
Mach kernel version:
	 Darwin Kernel Version 10.2.0: Tue Nov  3 10:37:10 PST 2009; root:xnu-1486.2.11~1/RELEASE_I386
Kernel configured for up to 2 processors.
440 processors are physically available.
220 processors are logically available.
Processor type: i486 (Intel 80486)
Processors active: 0 1
Primary memory available: 4.00 gigabytes
Default processor set: 72 tasks, 310 threads, 2 processors
Load average: 0.09, Mach factor: 1.90
      )
    end

    before do
      stub(Specjour::CPU).platform.returns('darwin')
      stub(Specjour::CPU).command.returns(hostinfo)
    end

    it "returns the number of physically available processors" do
      Specjour::CPU.cores.should == 440
    end
  end
end
