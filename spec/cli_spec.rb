require 'spec_helper'

describe Specjour::CLI do
  let(:fake_pid) { 100_000_000 }
  before do
    Specjour::CPU.stub(:cores => 27)
    Specjour::Dispatcher.stub(:new => stub.as_null_object)
    Specjour::Manager.stub(:new => stub.as_null_object)
    Specjour::Worker.stub(:new => stub.as_null_object)
    IO.stub(:popen => stub(:pid => fake_pid))
    Kernel.stub(:at_exit)
    Process.stub(:detach)
  end

  describe "#listen" do
    let(:manager) { stub.as_null_object }

    def manager_receives_options(options)
      expected_options = hash_including(options)
      Specjour::Manager.should_receive(:new).with(expected_options).and_return(manager)
    end

    it "defaults workers to system cores" do
      manager_receives_options("worker_size" => 27)
      Specjour::CLI.start %w(listen -p none)
    end

    it "accepts an array of projects to listen to" do
      manager_receives_options("registered_projects" => %w(one two three))
      Specjour::CLI.start %w(listen --projects one two three)
    end
  end

  describe "#dispatch" do
    let(:dispatcher) { stub.as_null_object }

    def dispatcher_receives_options(options)
      expected_options = hash_including(options)
      Specjour::Dispatcher.should_receive(:new).with(expected_options).and_return(dispatcher)
    end

    it "defaults path to the current directory" do
      Dir.stub(:pwd => "eh")
      dispatcher_receives_options("project_path" => "eh")
      Specjour::CLI.start %w(dispatch)
    end

    it "defaults workers to system cores" do
      dispatcher_receives_options("worker_size" => 27)
      Specjour::CLI.start %w(dispatch)
    end

    it "accepts a project alias" do
      dispatcher_receives_options("alias" => "eh")
      Specjour::CLI.start %w(dispatch --alias eh)
    end

    context "starting a manager" do
      let(:task) { task = Specjour::CLI.all_tasks['dispatch'] }

      before do
        Specjour::Dispatcher.stub(:new).and_return(stub.as_null_object)
      end

      it "attempts to start a manager" do
        cli = Specjour::CLI.new [], %w(--workers 2), {:task_options => task.options}
        cli.should_receive(:start_manager)
        cli.invoke(:dispatch)
      end

      it "doesn't start a manager when the worker size is less than one" do
        cli = Specjour::CLI.new [], %w(--workers 0), {:task_options => task.options}
        cli.should_not_receive(:start_manager)
        cli.invoke(:dispatch)
      end
    end
  end

  describe "#work" do
    it "starts a worker with the required parameters" do
      worker = stub.as_null_object
      args = {'project_path' => "eh", 'printer_uri' => "specjour://1.1.1.1:12345", 'number' => 1}
      Specjour::Worker.should_receive(:new).with(hash_including(args)).and_return(worker)
      Specjour::CLI.start %w(work --project-path eh --printer-uri specjour://1.1.1.1:12345 --number 1)
    end
  end

  describe "#handle_logging" do
    before do
      subject.stub(:options => {})
    end

    it "enables logging" do
      subject.options['log'] = true
      Specjour.should_receive(:new_logger).with(Logger::DEBUG).and_return(stub)
      subject.send(:handle_logging)
    end

    it "doesn't enable logging" do
      Specjour.should_not_receive(:new_logger)
      subject.send(:handle_logging)
    end
  end

  describe "#start_manager" do
    it "starts a listener in a subprocess" do
      subject.stub(:args => {:project_path => 'eh', :worker_size => 1})
      command = %(specjour listen --projects eh --workers 1)
      IO.should_receive(:popen).with(command).and_return(stub(:pid => fake_pid))
      subject.send(:start_manager)
    end

    it "detaches the subprocess' pid" do
      Process.should_receive(:detach).with(fake_pid)
      subject.send :start_manager
    end

    it "does something at exit" do
      Kernel.should_receive(:at_exit)
      subject.send :start_manager
    end
  end
end
