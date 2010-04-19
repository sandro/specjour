require 'spec_helper'

describe Specjour::CLI do
  before do
    Specjour::CPU.stub(:cores => 27)
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
      manager_receives_options("projects" => %w(one two three))
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
end
