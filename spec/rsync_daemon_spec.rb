require 'spec_helper'

describe Specjour::RsyncDaemon do
  subject do
    Specjour::RsyncDaemon.new('/tmp/seasonal', 'seasonal')
  end

  before do
    stub(Kernel).system
    stub(Kernel).at_exit
    stub(subject).write_config
  end

  specify { subject.config_directory.should == '/tmp/seasonal/.specjour' }
  specify { subject.config_file.should == '/tmp/seasonal/.specjour/rsyncd.conf' }

  describe "#start" do
    it "writes the config" do
      mock(subject).write_config
      subject.start
    end

    it "executes the system command" do
      mock(Kernel).system(*subject.send(:command))
      subject.start
    end

    it "stops at_exit" do
      mock(subject).stop
      mock.proxy(Kernel).at_exit.yields(subject)
      subject.start
    end
  end

  describe "#stop" do
    context "with pid" do
      before do
        stub(subject).pid.returns(100_000_000)
        stub(Process).kill
        stub(FileUtils).rm
      end

      it "kills the pid with TERM" do
        mock(Process).kill('TERM', subject.pid)
        subject.stop
      end

      it "removes the pid file" do
        mock(FileUtils).rm(subject.pid_file)
        subject.stop
      end
    end

    context "without pid" do
      it "does nothing" do
        stub(subject).pid
        subject.stop.should be_nil
      end
    end
  end
end
