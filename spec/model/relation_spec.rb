# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Relation do
  describe '.where' do
    context "for base classes" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.use ActiveService::Middleware::ParseJSON
          builder.adapter :test do |stub|
            stub.get("/users?foo=1&bar=2") { |env| ok! [{ :id => 2, :name => "Tobias Fünke" }] }
            stub.get("/users?admin=1") { |env| ok! [{ :id => 1, :name => "Tobias Fünke" }] }

            stub.get("/users") do |env|
              ok! [
                { :id => 1, :name => "Tobias Fünke" },
                { :id => 2, :name => "Lindsay Fünke" },
                @created_user,
              ].compact
            end

            stub.post('/users') do |env|
              @created_user = { :id => 3, :name => 'George Michael Bluth' }
              ok! @created_user
            end
          end
        end

        spawn_model "User" do
          uses_api api
          attribute :name
        end
      end

      it "doesn't fetch the data immediatly" do
        expect(User).to receive(:request).never
        @users = User.where(:admin => 1)
      end

      it "fetches the data and passes query parameters" do
        expect(User).to receive(:request).once.and_call_original
        @users = User.where(:admin => 1)
        expect(@users).to respond_to(:length)
        expect(@users.size).to be 1
      end

      it "chains multiple where statements" do
        @user = User.where(:foo => 1).where(:bar => 2).first
        expect(@user.id).to eq 2
      end

      it "does not reuse relations" do
        expect(User.all.size).to be 2
        expect(User.create(:name => 'George Michael Bluth').id).to be 3
        expect(User.all.size).to be 3
      end

      it "responds to first and last" do
        expect(User).to respond_to :first
        expect(User).to respond_to :last
      end
    end

    context "for parent class" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.use ActiveService::Middleware::ParseJSON
          builder.adapter :test do |stub|
            stub.get("/users?page=2") { |env| ok! [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }] }
          end
        end

        spawn_model("Model") do
          uses_api api
          scope :page, lambda { |page| where(:page => page) }
        end

        class User < Model; end
        @spawned_models << :User
      end

      it "propagates the scopes through its children" do
        @users = User.page(2)
        expect(@users.length).to be 2
      end
    end
  end

  describe '.order' do
    before do
      api = ActiveService::API.new :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users?name=foo&sort=name_asc") { |env| ok! [{ :id => 3, :name => "foo a" }, { :id => 4, :name => "foo b" }] }
          stub.get("/users?sort=name_asc") { |env| ok! [{ :id => 2, :name => "Lindsay Fünke" }, { :id => 1, :name => "Tobias Fünke" }] }
          stub.get("/users?sort=name_desc") { |env| ok! [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }] }
          stub.get("/admin_users?UserName=foo&sort=UserName_asc") { |env| ok! [{ :id => 3, :UserName => "foo a" }, { :id => 4, :UserName => "foo b" }] }
          stub.get("/admin_users?sort=UserName_asc") { |env| ok! [{ :id => 2, :UserName => "Lindsay Fünke" }, { :id => 1, :UserName => "Tobias Fünke" }] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
      end

      spawn_model "AdminUser" do
        uses_api api
        attribute :name, :source => "UserName"
      end
    end

    it "doesn't fetch the data immediatly" do
      expect(User).to receive(:request).never
      @users = User.order(:name)
    end

    it "fetches the data and passes query parameters" do
      expect(User).to receive(:request).once.and_call_original
      @users = User.order(:name)
      expect(@users).to respond_to(:length)
      expect(@users.size).to be 2
    end

    it "orders in ascending order by default" do
      @users = User.order(:name)
      expect(@users.first.name).to eq "Lindsay Fünke"
      expect(@users.last.name).to eq "Tobias Fünke"
    end

    it "orders in ascending order when :asc is specified" do
      @users = User.order(:name => :asc)
      expect(@users.first.name).to eq "Lindsay Fünke"
      expect(@users.last.name).to eq "Tobias Fünke"
    end

    it "orders in descending order when :desc is specified" do
      @users = User.order(:name => :desc)
      expect(@users.first.name).to eq "Tobias Fünke"
      expect(@users.last.name).to eq "Lindsay Fünke"
    end

    it "orders parameters with different source names" do
      @users = AdminUser.order(:name)
      expect(@users.first.name).to eq "Lindsay Fünke"
      expect(@users.last.name).to eq "Tobias Fünke"
    end

    it "orders string parameters" do
      @users = User.order("name")
      expect(@users.first.name).to eq "Lindsay Fünke"
      expect(@users.last.name).to eq "Tobias Fünke"
    end

    it "orders string parameters with different source names" do
      @users = AdminUser.order("name")
      expect(@users.first.name).to eq "Lindsay Fünke"
      expect(@users.last.name).to eq "Tobias Fünke"
    end

    it "can be chained with where statement" do
      @users = User.where(:name => "foo").order(:name)
      expect(@users.first.name).to eq "foo a"
      expect(@users.last.name).to eq "foo b"
    end

    it "can be chained with where statement and with different source names" do
      @users = AdminUser.where(:name => "foo").order(:name)
      expect(@users.first.name).to eq "foo a"
      expect(@users.last.name).to eq "foo b"
    end
  end

  describe '.limit' do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users?limit=2") { |env| ok! [{:id => 1, :name => "Tobias Fünke"}, {:id => 2, :name => "Lindsay Fünke"}] }
          stub.get("/users?name=foo&limit=1") { |env| ok! [{:id => 1, :name => "foo"}] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
      end
    end

    it "doesn't fetch the data immediatly" do
      expect(User).to receive(:request).never
      User.limit(2)
    end

    it "limits the number of results" do
      expect(User.limit(2).size).to be 2
    end

    it "can be chained with where statements" do
      @users = User.where(:name => "foo").limit(1)
      expect(@users.size).to be 1
    end
  end

  describe '.create' do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! :id => 1, :name => "Tobias Fünke", :email => "tobias@bluth.com" }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        attribute :email
      end
    end

    context "with a single where call" do
      it "creates a resource and passes the query parameters" do
        @user = User.where(:name => "Tobias Fünke", :email => "tobias@bluth.com").create
        expect(@user.id).to be 1
        expect(@user.name).to eq "Tobias Fünke"
        expect(@user.email).to eq "tobias@bluth.com"
      end
    end

    context "with multiple where calls" do
      it "creates a resource and passes the query parameters" do
        @user = User.where(:fullname => "Tobias Fünke").create(:email => "tobias@bluth.com")
        expect(@user.id).to be 1
        expect(@user.name).to eq "Tobias Fünke"
        expect(@user.email).to eq "tobias@bluth.com"
      end
    end
  end

  describe '.build' do
    before do
      spawn_model "User" do
        attribute :name
      end
    end

    it "handles new resource with build" do
      @new_user = User.where(:name => "Tobias Fünke").build
      expect(@new_user.new?).to be_truthy
      expect(@new_user.name).to eq "Tobias Fünke"
    end
  end

  describe '.scope' do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users?what=4&where=3") { |env| ok! [{ :id => 3, :name => "Maeby Fünke" }] }
          stub.get("/users?what=2") { |env| ok! [{ :id => 2, :name => "Lindsay Fünke" }] }
          stub.get("/users?where=6") { |env| ok! [{ :id => 4, :name => "Tobias Fünke" }] }
        end
      end

      spawn_model 'User' do
        uses_api api
        scope :foo, lambda { |v| where(:what => v) }
        scope :bar, lambda { |v| where(:where => v) }
        scope :baz, lambda { bar(6) }
      end
    end

    it "passes query parameters" do
      @user = User.foo(2).first
      expect(@user.id).to be 2
    end

    it "passes multiple query parameters" do
      @user = User.foo(4).bar(3).first
      expect(@user.id).to be 3
    end

    it "handles embedded scopes" do
      @user = User.baz.first
      expect(@user.id).to be 4
    end
  end

  describe '.default_scope' do
    context "for new objects" do
      before do
        spawn_model 'User' do
          attribute :active
          attribute :admin

          default_scope lambda { where(:active => true) }
          default_scope lambda { where(:admin => true) }
        end
      end

      it "should apply the scope to the attributes" do
        expect(User.new).to be_active
        expect(User.new).to be_admin
      end
    end

    context "for fetched resources" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.use ActiveService::Middleware::ParseJSON
          builder.adapter :test do |stub|
            stub.post("/users") { |env| ok! :id => 3, :active => true }
          end
        end

        spawn_model 'User' do
          uses_api api
          attribute :active
          default_scope lambda { where(:active => true) }
        end
      end

      it "should apply the scope to the request" do
        expect(User.create).to be_active
      end
    end

    context "for fetched collections" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.use ActiveService::Middleware::ParseJSON
          builder.adapter :test do |stub|
            stub.get("/users?active=true") { |env| ok! [{ :id => 3, :active => (params(env)[:active] == "true" ? true : false) }] }
          end
        end

        spawn_model 'User' do
          uses_api api
          attribute :active
          default_scope lambda { where(:active => true) }
        end
      end

      it "should apply the scope to the request" do
        expect(User.all.first).to be_active
      end
    end
  end

  describe '.map' do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users") do |env|
            ok! [{ :id => 1, :name => "Tobias Fünke" }, { :id => 2, :name => "Lindsay Fünke" }]
          end
        end
      end

      spawn_model 'User' do
        uses_api api
        attribute :name
      end
    end

    it "delegates the method to the fetched collection" do
      expect(User.all.map(&:name)).to eq ["Tobias Fünke", "Lindsay Fünke"]
    end
  end
end
