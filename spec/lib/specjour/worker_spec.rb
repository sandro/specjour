require 'spec_helper'

class CustomException < RuntimeError
end

def boo
  raise CustomException, 'fails'
end

describe Specjour::Worker do
  it "fails" do
    boo
  end
end
