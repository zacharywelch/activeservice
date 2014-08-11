require 'spec_helper'

describe ActiveService::Collection do

  let(:items) { [1, 2, 3, 4] }

  describe "#new" do
    context "without parameters" do
      subject { ActiveService::Collection.new }

      it { should eq([]) }
    end

    context "with parameters" do
      subject { ActiveService::Collection.new(items) }

      it { should eq([1,2,3,4]) }
    end
  end
end
