require 'spec_helper'

describe Specjour::RsyncDaemon do
  subject do
    Specjour::RsyncDaemon.new('/tmp/seasonal', 'seasonal', 8989)
  end

  before do
    stub(Kernel).system
    stub(Kernel).at_exit
    stub(Dir).chdir
    stub(File).open
    stub(File).read
    stub(FileUtils).rm
    stub(Process).kill
  end

  specify { subject.config_directory.should == '/tmp/seasonal/.specjour' }
  specify { subject.config_file.should == '/tmp/seasonal/.specjour/rsyncd.conf' }

  describe "#start" do
    it "writes the config" do
      mock(subject).write_config
      subject.start
    end

    it "executes the system command in the project directory" do
      mock(Kernel).system(*subject.send(:command))
      mock(Dir).chdir(subject.project_path).yields
      subject.start
    end

    it "stops at_exit" do
      mock(subject).stop
      mock.proxy(Kernel).at_exit.yields(subject)
      subject.start
    end

    it "allows setting a custom port" do
      mock(subject).port
      mock(Dir).chdir(subject.project_path).yields
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

  describe "#check_config_version" do
    it "warns when the version is out of date" do
      stub(File).read { "# 0.0.0\n" }
      mock($stderr).puts(/made changes/)
      subject.send(:check_config_version)
    end

    it "doesn't warn when the version isn't out of date" do
      stub(File).read { "# #{Specjour::RsyncDaemon::CONFIG_VERSION}\n" }
      dont_allow($stderr).puts
      subject.send(:check_config_version)
    end
  end

  describe "#write_config" do
    context "config exists" do
      it "checks if the config is out of date" do
        stub(File).exists?(anything) { true }
        mock(subject).check_config_version
        subject.send(:write_config)
      end
    end
  end
end
