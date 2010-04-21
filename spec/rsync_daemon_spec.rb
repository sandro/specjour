require 'spec_helper'

describe Specjour::RsyncDaemon do
  subject do
    Specjour::RsyncDaemon.new('/tmp/seasonal', 'seasonal')
  end

  before do
    stub(:system)
    stub(:at_exit)
    subject.stub(:write_config)
  end

  describe "#config_directory" do
    specify { subject.config_directory.should == '/tmp/seasonal/.specjour' }
  end

  describe "#config_file" do
    specify { subject.config_file.should == '/tmp/seasonal/.specjour/rsyncd.conf' }
  end

  describe "#start" do
    it "writes the config" do
      subject.should_receive(:write_config)
      subject.start
    end

    it "executes the system command" do
      subject.should_receive(:system).with(*subject.send(:command))
      subject.start
    end

    it "stops at_exit" do
      subject.should_receive(:at_exit)
      subject.start
    end
  end

  describe "#stop" do
    context "with pid" do
      before do
        subject.stub(:pid => 100_000_000)
        Process.stub(:kill)
        FileUtils.stub(:rm)
      end

      it "kills the pid with TERM" do
        Process.should_receive(:kill).with('TERM', subject.pid)
        subject.stop
      end

      it "removes the pid file" do
        FileUtils.should_receive(:rm).with(subject.pid_file)
        subject.stop
      end
    end

    context "without pid" do
      it "does nothing" do
        subject.stub(:pid => nil)
        subject.stop.should be_nil
      end
    end
  end
end
