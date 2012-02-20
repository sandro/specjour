require 'spec_helper'

describe Specjour::CLI do
  subject { Specjour::CLI.new }
  let(:fake_pid) { 100_000_000 }
  before do
    stub(Specjour::CPU).cores.returns(27)
  end

  describe "#listen" do
    let(:manager) { NullObject.new }

    before do
      stub(Dir).pwd { '/home/someone/myproject' }
    end

    def manager_receives_options(options)
      expected_options = hash_including(options)
      mock(Specjour::Manager).new(expected_options).returns(manager)
    end

    it "defaults workers to system cores" do
      manager_receives_options("worker_size" => 27)
      Specjour::CLI.start %w(listen)
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
      manager_receives_options("registered_projects" => %w(myproject))
      Specjour::CLI.start %w(listen)
    end
  end

  describe "#dispatch" do
    let(:dispatcher) { NullObject.new }
    before do
      stub(Dir).pwd { "/myproject" }
      stub(File).expand_path do |path|
        if path[0] == "/"
          path
        else
          "#{Dir.pwd}/#{path}".sub %r(/$), ''
        end
      end
    end

    def dispatcher_receives_options(options)
      expected_options = hash_including(options)
      mock(Specjour::Dispatcher).new(expected_options).returns(dispatcher)
    end

    it "defaults workers to system cores" do
      dispatcher_receives_options("worker_size" => 27)
      Specjour::CLI.start %w(dispatch)
    end

    it "accepts a project alias" do
      dispatcher_receives_options("project_alias" => "myproject_feature1")
      Specjour::CLI.start %w(dispatch --alias myproject_feature1)
    end

    it "defaults path to the current directory" do
      dispatcher_receives_options("project_path" => "/myproject")
      Specjour::CLI.start %w(dispatch)
    end

    it "accepts a port for rsync" do
      dispatcher_receives_options("rsync_port" => 9999)
      Specjour::CLI.start %w(dispatch --rsync-port 9999)
    end

    context "with path arguments" do

      it "accepts a spec file" do
        dispatcher_receives_options("project_path" => "/myproject", "test_paths" => ["spec/models/user_spec.rb"])
        Specjour::CLI.start %w(dispatch spec/models/user_spec.rb)
      end

      it "accepts a spec directory" do
        dispatcher_receives_options("project_path" => "/myproject", "test_paths" => ["spec/models"])
        Specjour::CLI.start %w(dispatch spec/models)
      end

      it "accepts multiple spec files" do
        dispatcher_receives_options("project_path" => "/myproject", "test_paths" => ["spec/models/user_spec.rb", "spec/models/account_spec.rb"])
        Specjour::CLI.start %w(dispatch spec/models/user_spec.rb spec/models/account_spec.rb)
      end

      it "accepts directories and files" do
        dispatcher_receives_options("project_path" => "/myproject", "test_paths" => ["spec/models", "spec/helpers/application_helper_spec.rb"])
        Specjour::CLI.start %w(dispatch spec/models spec/helpers/application_helper_spec.rb)
      end

      it "raises when a line number is present" do
        expect do
          Specjour::CLI.start(%w(dispatch spec/helpers/application_helper_spec.rb:5))
        end.to raise_error(ArgumentError)
      end
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

    it "sets the project path to '~/mydir'" do
      stub(File).expand_path {|f| f }
      dispatcher_receives_options("project_path" => "~/mydir")
      Specjour::CLI.start %w(prepare ~/mydir)
    end

    it "accepts a port for rsync" do
      dispatcher_receives_options("rsync_port" => 9999)
      Specjour::CLI.start %w(prepare --rsync-port 9999)
    end
  end
end
