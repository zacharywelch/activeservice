require './client.rb'

# NOTE: to run these specs you must have the service running locally. Do like this:
# ruby service.rb -p 3000 -e test

# Also note that after a single run of the tests the server must be restarted to reset
# the database. We could change this by deleting all users in the test setup.
describe "client" do
  before(:all) do
    User.base_uri = "http://localhost:3000"
    @user = User.create(name: "foo", email: "foo@bar.com")
  end

  let(:id) { @user["id"] }

  after(:all) do
    User.destroy(id)
  end

  it "should get a user" do
    user = User.find(id)
    user["name"].should  == "foo"
    user["email"].should == "foo@bar.com"
  end

  it "should return nil for a user not found" do
    User.find(-1).should be_nil
  end

  it "should create a user" do
    random_name = ('a'..'z').to_a.shuffle[0,8].join
    random_email = ('a'..'z').to_a.shuffle[0,8].join
    user = User.create(
      :name => random_name,
      :email => random_email)
    user['name'].should == random_name
    user['email'].should == random_email
    User.find(user['id']).should == user
  end

  it "should update a user" do
    user = User.update(id, :email => 'bar@foo.com')
    user['name'].should == 'foo'
    user['email'].should  == 'bar@foo.com'
    User.find(id).should == user
  end

  it "should destroy a user" do
    destroy_user = User.create(name: "destroy me", email: "destroy@me.com")
    User.destroy(destroy_user["id"]).should == true
    User.find(destroy_user["id"]).should be_nil
  end
end