require 'spec_helper.rb'

describe ActiveAttr::Attributes do
  
  describe "values option" do

    context "when values is an array" do
      before do
        spawn_model "Purchase" do
          attribute :status, values: %w(submitted approved shipped)
        end
      end

      let(:values) { %w(submitted approved shipped) }
      subject(:purchase) { Purchase.new }
      
      it "takes array of values" do
        expect(Purchase.attributes[:status][:values]).to be_an Array
        expect(Purchase.attributes[:status][:values]).to eq values
      end

      it "creates predicate for each value" do
        values.each do |value|
          expect(purchase).to respond_to("#{value}?")
        end
      end

      context "when attribute equals one of the values" do
        before { purchase.status = "approved" }
        it { should be_approved }
      end

      it "creates a scope for each value" do
        values.each do |value|
          expect(Purchase).to respond_to("#{value}")
        end
      end      
    end

    context "when values is a hash" do
      before do
        spawn_model "Purchase" do
          attribute :status, values: { submitted: 0, approved: 1, shipped: 2 }
        end
      end

      let(:values) { { submitted: 0, approved: 1, shipped: 2 } }
      subject(:purchase) { Purchase.new }
      
      it "takes hash of values" do
        expect(Purchase.attributes[:status][:values]).to be_a Hash
        expect(Purchase.attributes[:status][:values]).to eq values
      end

      it "creates predicate for each key in hash of values" do
        values.keys.each do |key|
          expect(purchase).to respond_to("#{key}?")
        end
      end

      context "when attribute equals one of the values" do
        before { purchase.status = 1 }
        it { should be_approved }
      end      
    end

    it "validates inclusion of values"    
  end
end