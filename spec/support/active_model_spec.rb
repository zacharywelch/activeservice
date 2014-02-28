shared_examples_for "active model" do
  require 'test/unit/assertions'
  include Test::Unit::Assertions  
  include ActiveModel::Lint::Tests

  # to_s is to support ruby-1.9
  ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
    example m.gsub('_',' ') do
      send m
    end
  end

  def model
    subject
  end

  describe "persistence" do
    it { should respond_to(:id) }
    it { should respond_to(:new?) }
    it { should respond_to(:new_record?) }
    it { should respond_to(:destroyed?) }

    context "when id is nil" do
      before { subject.id = nil }
      it { should_not be_persisted }
      it { should be_new }
    end

    context "when id is assigned" do
      before { subject.id = 1 }
      it { should be_persisted }
      it { should_not be_new }
    end

    describe "when saved" do
      before { subject.save }
      it { should_not be_new }
    end
  end

  describe "equality" do
    context "when other object is itself" do
      let(:other) { subject }
      it { should == other }
    end

    context "when other object has same attributes" do
      let(:other) { subject.class.new(subject.attributes) }
      it { should == other }
    end
  end

  describe "serialization" do
    it "should serialize to JSON" do
      subject.to_json.should == subject.attributes.to_json
    end

    it "should serialize from JSON" do
      subject.should == subject.class.new.from_json(subject.to_json)
    end
  end
end