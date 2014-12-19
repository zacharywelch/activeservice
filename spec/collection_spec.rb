require 'spec_helper'

describe ActiveService::Collection do

  let(:items) { [1, 2, 3, 4] }
  let(:malformed_items) { {:a=>"a"}.to_json }

  describe "#new" do
    context "without parameters" do
      subject { ActiveService::Collection.new }

      it { should eq([]) }
    end

    context "with parameters" do
      subject { ActiveService::Collection.new(items) }

      it { should eq([1,2,3,4]) }
    end

    context "with malformed parameters" do
      it "should raise a ParserError exception" do
        expect {ActiveService::Collection.new(malformed_items)}.to raise_error(
	  ActiveService::Errors::ParserError
        )
      end 
    end
  end
end
