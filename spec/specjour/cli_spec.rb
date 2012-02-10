require 'spec_helper'

describe Specjour::CLI do
  subject { Specjour::CLI.new }
  let(:fake_pid) { 100_000_000 }
  before do
    stub(Specjour::CPU).cores.returns(27)
    stub(Specjour::Dispatcher).new.returns(stub!)
    stub(Specjour::Manager).new.returns(stub!)
    stub(Specjour::Worker).new.returns(stub!)
  end

  describe "#listen" do
    let(:manager) { NullObject.new }

    before do
      stub(Dir).pwd { '/home/someone/foo-bar' }
    end

    def manager_receives_options(options)
      expected_options = hash_including(options)
      mock(Specjour::Manager).new(expected_options).returns(manager)
    end

    it "defaults workers to system cores" do
      manager_receives_options("worker_size" => 27)
      Specjour::CLI.start %w(listen -p none)
    end

    it "accepts an array of projects to listen to" do
      manager_receives_options("registered_projects" => %w(one two three))
      Specjour::CLI.start %w(listen --projects one two three)
    end

    it "accepts a port for rsync" do
      manager_receives_options("rsync_port" => 9999)
      Specjour::CLI.start %w(listen --rsync-port 9999)
    end

    it "listens to the current path by default" do
      manager_receives_options("registered_projects" => %w(foo-bar))
      Specjour::CLI.start %w(listen)
    end
  end

  describe "#dispatch" do
    let(:dispatcher) { NullObject.new }

    def dispatcher_receives_options(options)
      expected_options = hash_including(options)
      mock(Specjour::Dispatcher).new(expected_options).returns(dispatcher)
    end

    it "defaults path to the current directory" do
      stub(Dir).pwd.returns("eh")
      dispatcher_receives_options("project_path" => "eh")
      Specjour::CLI.start %w(dispatch)
    end

    it "defaults workers to system cores" do
      dispatcher_receives_options("worker_size" => 27)
      Specjour::CLI.start %w(dispatch)
    end

    it "accepts a project alias" do
      dispatcher_receives_options("project_alias" => "eh")
      Specjour::CLI.start %w(dispatch --alias eh)
    end

    it "accepts a port for rsync" do
      dispatcher_receives_options("rsync_port" => 9999)
      Specjour::CLI.start %w(dispatch --rsync-port 9999)
    end
  end

  describe "#work" do
    it "starts a worker with the required parameters" do
      worker = NullObject.new
      args = {'project_path' => "eh", 'printer_uri' => "specjour://1.1.1.1:12345", 'number' => 1, 'task' => 'run_tests'}
      mock(Specjour::Worker).new(hash_including(args)).returns(worker)
      Specjour::CLI.start %w(work --project-path eh --printer-uri specjour://1.1.1.1:12345 --number 1 --task run_tests)
    end
  end

  describe "#handle_logging" do
    before do
      stub(subject).options.returns({})
    end

    it "enables logging" do
      subject.options['log'] = true
      mock(Specjour).new_logger(Logger::DEBUG).returns(stub!)
      subject.send(:handle_logging)
    end

    it "doesn't enable logging" do
      dont_allow(Specjour).new_logger
      subject.send(:handle_logging)
    end
  end

  describe "#prepare" do
    let(:dispatcher) { NullObject.new }

    def dispatcher_receives_options(options)
      expected_options = hash_including(options)
      mock(Specjour::Dispatcher).new(expected_options).returns(dispatcher)
    end

    it "sets the worker task to 'prepare'" do
      dispatcher_receives_options("worker_task" => "prepare")
      Specjour::CLI.start %w(prepare)
    end

    it "accepts a port for rsync" do
      dispatcher_receives_options("rsync_port" => 9999)
      Specjour::CLI.start %w(prepare --rsync-port 9999)
    end
  end
end
