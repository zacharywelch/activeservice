require File.dirname(__FILE__) + "/../spec_helper.rb"

describe "user" do
  let(:attributes) { { name: 'foo', email: 'foo@bar.com' } }
  before do
    @user = User.new(attributes)
  end

  subject { @user }

  it_should_behave_like "ActiveModel"   

  it { should respond_to(:name) }
  it { should respond_to(:email) }

  it { should be_valid }

  describe "when name is not present" do
    before { @user.name = " " }
    it { should_not be_valid }
  end

  describe "when email is not present" do
    before { @user.email = " " }
    it { should_not be_valid }
  end

  describe "when name is too long" do
    before { @user.name = "a" * 51 }
    it { should_not be_valid }
  end

  describe "when email format is invalid" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.
                     foo@bar_baz.com foo@bar+baz.com]
      addresses.each do |invalid_address|
        @user.email = invalid_address
        @user.should_not be_valid
      end
    end
  end

  describe "when email format is valid" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        @user.email = valid_address
        @user.should be_valid
      end
    end
  end

  describe "when saved" do
    before do
      @user.email.upcase!
      @user.save
    end

    it "should downcase email" do
      @user.email.should == @user.email.downcase
    end
  end

  describe "when destroyed" do
    let(:destroy_user) do
      User.create(name: 'destroy user', email: 'destroy@user.com')
    end
    before { destroy_user.destroy }
    specify { destroy_user.should be_destroyed }
  end

  describe "when created" do
    let(:created_user) do
      User.create(name: 'destroy user', email: 'destroy@user.com')
    end
    specify { created_user.should be_persisted }
  end  
end