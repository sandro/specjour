require 'spec_helper'

class CustomException < RuntimeError
end

def boo
  raise CustomException, 'fails'
end

# shared_examples "a collection" do

#   it "responds to #each" do
#     expect(collection).to respond_to(:each)
#   end

# end

# shared_examples "a passing example" do
#   it "works" do
#     expect(true).to eq(true)
#   end
# end

describe Specjour do
  it "passes" do
    1.should == 1
  end

  # it "pends as an example" do
  #   pending
  # end

  # it "fails as an example" do
  #   boo
  # end

  # 2.times do |i|
  #   it "[#{i}] registers a unique example" do
  #     expect(true).to eq(true)
  #   end
  # end

  # it_behaves_like "a passing example"

  describe "testing before all" do
    before(:all) do
      @run_times = @run_times.to_i + 1
    end

    it "runs before(:all) once" do
      expect(@run_times).to eq(1)
    end

    it "runs before(:all) once and only once" do
      expect(@run_times).to eq(1)
    end

  end

#     it "runs before(:all) once maybe" do
#       # expect(@run_times).to eq(1)
#       expect(1).to eq(1)
#     end

  #   describe "testing nested before all" do
  #     before(:all) do
  #       @run_times += 1
  #     end

  #     it "runs before(:all) twice" do
  #       expect(@run_times).to eq(2)
  #     end

  #   end
  # end

  describe "testing before each" do
    before(:each) do
      puts "1"
      @zee = 1
      @run_times = @run_times.to_i + 1
    end

    it "runs before(:each) once" do
          puts "zee is #{@zee}"
      expect(@run_times).to eq(1)
    end

    it "runs before(:each) once" do
          puts "zee is #{@zee}"
      expect(@run_times).to eq(1)
    end

    describe "testing before all" do
      before(:each) do
        puts "2"
        @zaa = 2
        @zee = 2
      end
      # before(:all) do
      #   @run_times = @run_times.to_i + 1
      # end

      it "runs before(:all) once" do
          puts "zee is #{@zee}"
        expect(@run_times).to eq(2)
      end

      describe "deeply nested" do
        before(:each) do
          puts "3"
          @zee = 3
        end

        it "works" do
          puts "zee is #{@zee}"
          puts "zaa is #{@zaa}"
          expect(@run_times).to eq(2)
        end
      end
    end
  end

  #   describe "testing nested before each" do
  #     before(:each) do
  #       @run_times = @run_times.to_i + 1
  #     end

  #     it "works" do
  #       expect(@run_times).to eq(2)
  #     end
  #   end
  # end

  # describe "letters" do
  #   let(:collection) { %w(A B C) }

  #   it_behaves_like "a collection"
  # end
end
