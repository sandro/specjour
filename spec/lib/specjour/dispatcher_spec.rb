require 'spec_helper'

describe Specjour::Dispatcher do
  let(:dispatcher) { Specjour::Dispatcher.new('.') }
  def new_worker
    Specjour::Worker.new
  end

  context "when splitting specs amongst workers" do
    before do
      dispatcher.stub(:work => lambda {})
    end

    it "divides 3 specs among one worker" do
      dispatcher.stub(:all_specs => %w(one two three))
      dispatcher.stub(:workers => [new_worker])
      dispatcher.send(:dispatch_work)
      dispatcher.workers[0].specs_to_run.should == %w(one two three)
    end

    it "divides 1 spec among two workers" do
      dispatcher.stub(:all_specs => %w(one))
      dispatcher.stub(:workers => [new_worker, new_worker])
      dispatcher.send(:dispatch_work)
      dispatcher.workers[0].specs_to_run.should == %w(one)
      dispatcher.workers[1].specs_to_run.should be_empty
    end

    it "divides 2 specs among two workers" do
      dispatcher.stub(:all_specs => %w(one two))
      dispatcher.stub(:workers => [new_worker, new_worker])
      dispatcher.send(:dispatch_work)
      dispatcher.workers[0].specs_to_run.should == %w(one)
      dispatcher.workers[1].specs_to_run.should == %w(two)
    end

    it "divides 2 specs among 5 workers" do
      dispatcher.stub(:all_specs => %w(one two))
      dispatcher.stub(:workers => [new_worker, new_worker, new_worker, new_worker, new_worker])
      dispatcher.send(:dispatch_work)
      dispatcher.workers[0].specs_to_run.should == %w(one)
      dispatcher.workers[1].specs_to_run.should == %w(two)
      dispatcher.workers[2].specs_to_run.should be_empty
      dispatcher.workers[3].specs_to_run.should be_empty
      dispatcher.workers[4].specs_to_run.should be_empty
    end

    it "divides 3 specs among two workers" do
      dispatcher.stub(:all_specs => %w(one two three))
      dispatcher.stub(:workers => [new_worker, new_worker])
      dispatcher.send(:dispatch_work)
      dispatcher.workers[0].specs_to_run.should == %w(one)
      dispatcher.workers[1].specs_to_run.should == %w(two three)
    end

    it "divides 16 specs among three workers" do
      dispatcher.stub(:all_specs => (1..16).to_a)
      dispatcher.stub(:workers => [new_worker, new_worker, new_worker])
      dispatcher.send(:dispatch_work)
      dispatcher.workers[0].specs_to_run.should == (1..5).to_a
      dispatcher.workers[1].specs_to_run.should == (6..10).to_a
      dispatcher.workers[2].specs_to_run.should == (11..16).to_a
    end
  end
end
