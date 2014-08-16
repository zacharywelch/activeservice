# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Associations do
  context "setting associations without details" do
    before { spawn_model "User" }
    subject { User.associations }

    context "single has_many association" do
      before { User.has_many :comments }
      its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Comment", :path => "/comments", :inverse_of => nil }] }
    end

    context "multiple has_many associations" do
      before do
        User.has_many :comments
        User.has_many :posts
      end

      its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Comment", :path => "/comments", :inverse_of => nil }, { :name => :posts, :data_key => :posts, :default => [], :class_name => "Post", :path => "/posts", :inverse_of => nil }] }
    end

    context "single has_one association" do
      before { User.has_one :category }
      its([:has_one]) { should eql [{ :name => :category, :data_key => :category, :default => nil, :class_name => "Category", :path => "/category" }] }
    end

    context "multiple has_one associations" do
      before do
        User.has_one :category
        User.has_one :role
      end

      its([:has_one]) { should eql [{ :name => :category, :data_key => :category, :default => nil, :class_name => "Category", :path => "/category" }, { :name => :role, :data_key => :role, :default => nil, :class_name => "Role", :path => "/role" }] }
    end

    context "single belongs_to association" do
      before { User.belongs_to :organization }
      its([:belongs_to]) { should eql [{ :name => :organization, :data_key => :organization, :default => nil, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }] }
    end

    context "multiple belongs_to association" do
      before do
        User.belongs_to :organization
        User.belongs_to :family
      end

      its([:belongs_to]) { should eql [{ :name => :organization, :data_key => :organization, :default => nil, :class_name => "Organization", :foreign_key => "organization_id", :path => "/organizations/:id" }, { :name => :family, :data_key => :family, :default => nil, :class_name => "Family", :foreign_key => "family_id", :path => "/families/:id" }] }
    end
  end

  context "setting associations with details" do
    before { spawn_model "User" }
    subject { User.associations }

    context "in base class" do
      context "single has_many association" do
        before { User.has_many :comments, :class_name => "Post", :inverse_of => :admin, :data_key => :user_comments, :default => {} }
        its([:has_many]) { should eql [{ :name => :comments, :data_key => :user_comments, :default => {}, :class_name => "Post", :path => "/comments", :inverse_of => :admin }] }
      end

      context "single has_one association" do
        before { User.has_one :category, :class_name => "Topic", :foreign_key => "topic_id", :data_key => :topic, :default => nil }
        its([:has_one]) { should eql [{ :name => :category, :data_key => :topic, :default => nil, :class_name => "Topic", :foreign_key => "topic_id", :path => "/category" }] }
      end

      context "single belongs_to association" do
        before { User.belongs_to :organization, :class_name => "Business", :foreign_key => "org_id", :data_key => :org, :default => true }
        its([:belongs_to]) { should eql [{ :name => :organization, :data_key => :org, :default => true, :class_name => "Business", :foreign_key => "org_id", :path => "/organizations/:id" }] }
      end
    end

    context "in parent class" do
      before { User.has_many :comments, :class_name => "Post" }

      describe "associations accessor" do
        subject { Class.new(User).associations }
        its(:object_id) { should_not eql User.associations.object_id }
        its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Post", :path => "/comments", :inverse_of => nil }] }
      end
    end
  end

  context "handling associations without details" do
    before do
      api = ActiveService::API.new :url => "https://api.example.com" do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :comments => [{ :comment => { :id => 2, :body => "Tobias, you blow hard!", :user_id => 1 } }, { :comment => { :id => 3, :body => "I wouldn't mind kissing that man between the cheeks, so to speak", :user_id => 1 } }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 1, :name => "Bluth Company" }, :organization_id => 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 2 }.to_json] }
          stub.get("/users/1/comments") { |env| [200, {}, [{ :comment => { :id => 4, :body => "They're having a FIRESALE?", :user_id => 1 } }].to_json] }
          stub.get("/users/2/comments") { |env| [200, {}, [{ :comment => { :id => 4, :body => "They're having a FIRESALE?" } }, { :comment => { :id => 5, :body => "Is this the tiny town from Footloose?" } }].to_json] }
          stub.get("/users/2/comments/5") { |env| [200, {}, { :comment => { :id => 5, :body => "Is this the tiny town from Footloose?" } }.to_json] }
          stub.get("/users/2/role") { |env| [200, {}, { :id => 2, :body => "User" }.to_json] }
          stub.get("/users/1/role") { |env| [200, {}, { :id => 3, :body => "User" }.to_json] }
          stub.get("/users/1/posts") { |env| [200, {}, [{:id => 1, :body => 'blogging stuff', :admin_id => 1 }].to_json] }
          stub.get("/organizations/1") { |env| [200, {}, { :organization =>  { :id => 1, :name => "Bluth Company Foo" } }.to_json] }
          stub.post("/users") { |env| [200, {}, { :id => 5, :name => "Mr. Krabs", :comments => [{ :comment => { :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 } }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }
          stub.put("/users/5") { |env| [200, {}, { :id => 5, :name => "Clancy Brown", :comments => [{ :comment => { :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 } }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }
          stub.delete("/users/5") { |env| [200, {}, { :id => 5, :name => "Clancy Brown", :comments => [{ :comment => { :id => 99, :body => "Rodríguez, nasibisibusi?", :user_id => 5 } }], :role => { :id => 1, :body => "Admin" }, :organization => { :id => 3, :name => "Krusty Krab" }, :organization_id => 3 }.to_json] }

          stub.get("/organizations/2") do |env|
            if env[:params]["admin"] == "true"
              [200, {}, { :organization => { :id => 2, :name => "Bluth Company (admin)" } }.to_json]
            else
              [200, {}, { :organization => { :id => 2, :name => "Bluth Company" } }.to_json]
            end
          end
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        attribute :organization_id
        has_many :comments
        has_one :role
        belongs_to :organization
        has_many :posts, :inverse_of => :admin
      end
      spawn_model "Comment" do
        uses_api api
        attribute :body
        attribute :user_id
        belongs_to :user
        parse_root_in_json true
      end
      spawn_model "Post" do
        uses_api api
        attribute :body
        attribute :admin_id
        belongs_to :admin, :class_name => 'User'
      end

      spawn_model "Organization" do
        uses_api api
        attribute :name
        parse_root_in_json true
      end

      spawn_model "Role" do
        uses_api api
        attribute :body
      end

      @user_with_included_data = User.find(1)
      @user_without_included_data = User.find(2)
    end

    let(:user_with_included_data_after_create) { User.create }
    let(:user_with_included_data_after_save_existing) { User.save_existing(5, :name => "Clancy Brown") }
    let(:user_with_included_data_after_destroy) { User.new(:id => 5).destroy }
    let(:comment_without_included_parent_data) { Comment.new(:id => 7, :user_id => 1) }

    it "maps an array of included data through has_many" do
      expect(@user_with_included_data.comments.first).to be_a(Comment)
      expect(@user_with_included_data.comments.length).to be 2
      expect(@user_with_included_data.comments.first.id).to be 2
      expect(@user_with_included_data.comments.first.body).to eq "Tobias, you blow hard!"
    end

    it "does not refetch the parents models data if they have been fetched before" do
      expect(@user_with_included_data.comments.first.user.object_id).to eq @user_with_included_data.object_id
    end

    it "does fetch the parent models data only once" do
      expect(comment_without_included_parent_data.user.object_id).to eq comment_without_included_parent_data.user.object_id
    end

    it "does fetch the parent models data that was cached if called with parameters" do
      expect(comment_without_included_parent_data.user.object_id).to_not eq comment_without_included_parent_data.user.where(:a => 2).object_id
    end

    it "uses the given inverse_of key to set the parent model" do
      expect(@user_with_included_data.posts.first.admin.object_id).to eq @user_with_included_data.object_id
    end

    it "fetches data that was not included through has_many" do
      expect(@user_without_included_data.comments.first).to be_a(Comment)
      expect(@user_without_included_data.comments.length).to be 2
      expect(@user_without_included_data.comments.first.id).to be 4
      expect(@user_without_included_data.comments.first.body).to eq "They're having a FIRESALE?"
    end

    it "fetches has_many data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.comments.where(:foo_id => 1).length).to be 1
    end

    it "fetches data that was not included through has_many only once" do
      expect(@user_without_included_data.comments.first.object_id).to eq @user_without_included_data.comments.first.object_id
    end

    xit "fetches data that was cached through has_many if called with parameters" do
      @user_without_included_data.comments.first.object_id.should_not == @user_without_included_data.comments.where(:foo_id => 1).first.object_id
    end

    xit "maps an array of included data through has_one" do
      @user_with_included_data.role.should be_a(Role)
      @user_with_included_data.role.object_id.should == @user_with_included_data.role.object_id
      @user_with_included_data.role.id.should == 1
      @user_with_included_data.role.body.should == "Admin"
    end

    xit "fetches data that was not included through has_one" do
      @user_without_included_data.role.should be_a(Role)
      @user_without_included_data.role.id.should == 2
      @user_without_included_data.role.body.should == "User"
    end

    xit "fetches has_one data even if it was included, only if called with parameters" do
      @user_with_included_data.role.where(:foo_id => 2).id.should == 3
    end

    xit "maps an array of included data through belongs_to" do
      @user_with_included_data.organization.should be_a(Organization)
      @user_with_included_data.organization.id.should == 1
      @user_with_included_data.organization.name.should == "Bluth Company"
    end

    xit "fetches data that was not included through belongs_to" do
      @user_without_included_data.organization.should be_a(Organization)
      @user_without_included_data.organization.id.should == 2
      @user_without_included_data.organization.name.should == "Bluth Company"
    end

    xit "fetches belongs_to data even if it was included, only if called with parameters" do
      @user_with_included_data.organization.where(:foo_id => 1).name.should == "Bluth Company Foo"
    end

    xit "can tell if it has a association" do
      @user_without_included_data.has_association?(:unknown_association).should be false
      @user_without_included_data.has_association?(:organization).should be true
    end

    xit "fetches the resource corresponding to a named association" do
      @user_without_included_data.get_association(:unknown_association).should be_nil
      @user_without_included_data.get_association(:organization).name.should == "Bluth Company"
    end

    xit "pass query string parameters when additional arguments are passed" do
      @user_without_included_data.organization.where(:admin => true).name.should == "Bluth Company (admin)"
      @user_without_included_data.organization.name.should == "Bluth Company"
    end

    xit "fetches data with the specified id when calling find" do
      comment = @user_without_included_data.comments.find(5)
      comment.id.should eq(5)
    end

    xit "'s associations responds to #empty?" do
      @user_without_included_data.organization.respond_to?(:empty?).should be_truthy
      @user_without_included_data.organization.should_not be_empty
    end

    xit 'includes has_many relationships in params by default' do
      params = @user_with_included_data.to_params
      params[:comments].should be_kind_of(Array)
      params[:comments].length.should eq(2)
    end

    [:create, :save_existing, :destroy].each do |type|
      context "after #{type}" do
        let(:subject) { self.send("user_with_included_data_after_#{type}")}

        xit "maps an array of included data through has_many" do
          subject.comments.first.should be_a(Comment)
          subject.comments.length.should == 1
          subject.comments.first.id.should == 99
          subject.comments.first.body.should == "Rodríguez, nasibisibusi?"
        end

        xit "maps an array of included data through has_one" do
          subject.role.should be_a(Role)
          subject.role.id.should == 1
          subject.role.body.should == "Admin"
        end
      end
    end
  end

  context "handling associations with details" do
    before do
      ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::FirstLevelParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :organization => { :id => 1, :name => "Bluth Company Inc." }, :organization_id => 1 }.to_json] }
          stub.get("/users/4") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke", :organization => { :id => 1, :name => "Bluth Company Inc." } }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :organization_id => 1 }.to_json] }
          stub.get("/users/3") { |env| [200, {}, { :id => 2, :name => "Lindsay Fünke", :company => nil }.to_json] }
          stub.get("/companies/1") { |env| [200, {}, { :id => 1, :name => "Bluth Company" }.to_json] }
        end
      end

      spawn_model "User" do
        belongs_to :company, :path => "/organizations/:id", :foreign_key => :organization_id, :data_key => :organization
      end

      spawn_model "Company"

      @user_with_included_data = User.find(1)
      @user_without_included_data = User.find(2)
      @user_with_included_nil_data = User.find(3)
      @user_with_included_data_but_no_fk = User.find(4)
    end

    xit "maps an array of included data through belongs_to" do
      @user_with_included_data.company.should be_a(Company)
      @user_with_included_data.company.id.should == 1
      @user_with_included_data.company.name.should == "Bluth Company Inc."
    end

    xit "does not map included data if it’s nil" do
      @user_with_included_nil_data.company.should be_nil
    end

    xit "fetches data that was not included through belongs_to" do
      @user_without_included_data.company.should be_a(Company)
      @user_without_included_data.company.id.should == 1
      @user_without_included_data.company.name.should == "Bluth Company"
    end

    xit "does not require foreugn key to have nested object" do
      @user_with_included_data_but_no_fk.company.name.should == "Bluth Company Inc."
    end
  end

  context "object returned by the association method" do
    before do
      spawn_model "Role" do
        def present?
          "of_course"
        end
      end
      spawn_model "User" do
        has_one :role
      end
    end

    let(:associated_value) { Role.new }
    let(:user_with_role) do
      User.new.tap { |user| user.role = associated_value }
    end

    subject { user_with_role.role }

    xit "doesnt mask the object's basic methods" do
      subject.class.should == Role
    end

    xit "doesnt mask core methods like extend" do
      committer = Module.new
      subject.extend  committer
      associated_value.should be_kind_of committer
    end

    xit "can return the association object" do
      subject.association.should be_kind_of ActiveService::Model::Associations::Association
    end

    xit "still can call fetch via the association" do
      subject.association.fetch.should eq associated_value
    end

    xit "calls missing methods on associated value" do
      subject.present?.should == "of_course"
    end

    xit "can use association methods like where" do
      subject.where(role: 'committer').association.
        params.should include :role
    end
  end

  context "building and creating association data" do
    before do
      spawn_model "Comment"
      spawn_model "User" do
        has_many :comments
      end
    end

    context "with #build" do
      xit "takes the parent primary key" do
        @comment = User.new(:id => 10).comments.build(:body => "Hello!")
        @comment.body.should == "Hello!"
        @comment.user_id.should == 10
      end
    end

    context "with #create" do
      before do
        ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.use ActiveService::Middleware::FirstLevelParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/10") { |env| [200, {}, { :id => 10 }.to_json] }
            stub.post("/comments") { |env| [200, {}, { :id => 1, :body => Faraday::Utils.parse_query(env[:body])['body'], :user_id => Faraday::Utils.parse_query(env[:body])['user_id'].to_i }.to_json] }
          end
        end

        User.use_api ActiveService::API.default_api
        Comment.use_api ActiveService::API.default_api
      end

      xit "takes the parent primary key and saves the resource" do
        @user = User.find(10)
        @comment = @user.comments.create(:body => "Hello!")
        @comment.id.should == 1
        @comment.body.should == "Hello!"
        @comment.user_id.should == 10
        @user.comments.should == [@comment]
      end
    end

    context "with #new" do
      xit "creates nested models from hash attibutes" do
        user = User.new(:name => "vic", :comments => [{:text => "hello"}])
        user.comments.first.text.should == "hello"
      end

      xit "assigns nested models if given as already constructed objects" do
        bye = Comment.new(:text => "goodbye")
        user = User.new(:name => 'vic', :comments => [bye])
        user.comments.first.text.should == 'goodbye'
      end
    end
  end
end
