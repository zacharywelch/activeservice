# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")
require 'pry'
describe ActiveService::Model::Associations do
  context "setting associations without details" do
    before { spawn_model "User" }
    subject { User.associations }

    context "single has_many association" do
      before { User.has_many :comments }
      its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Comment", :path => nil, :inverse_of => nil }] }
    end

    context "multiple has_many associations" do
      before do
        User.has_many :comments
        User.has_many :posts
      end

      its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Comment", :path => nil, :inverse_of => nil }, { :name => :posts, :data_key => :posts, :default => [], :class_name => "Post", :path => nil, :inverse_of => nil }] }
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
        its([:has_many]) { should eql [{ :name => :comments, :data_key => :user_comments, :default => {}, :class_name => "Post", :path => nil, :inverse_of => :admin }] }
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
        its([:has_many]) { should eql [{ :name => :comments, :data_key => :comments, :default => [], :class_name => "Post", :path => nil, :inverse_of => nil }] }
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
          stub.get("/users/1/posts") { |env| [200, {}, [{:id => 1, :body => 'blogging stuff', :admin_id => 1, :approved => true }, {:id => 2, :body => 'personal stuff', :admin_id => 1, :approved => false }].to_json] }
          stub.get("/users/2/timesheets?status=approved&hours=40") { |env| [200, {}, [{ :id => 2, :status => 'approved', :hours => 40, :user_id => 2 }].to_json] }
          stub.get("/users/2/timesheets?status=approved") { |env| [200, {}, [{ :id => 1, :status => 'approved', :hours => 20, :user_id => 2 }, { :id => 2, :status => 'approved', :hours => 40, :user_id => 2 }].to_json] }
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
        has_many :timesheets
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

      spawn_model "Timesheet" do
        uses_api api
        collection_path "users/:user_id/timesheets"
        attribute :status
        attribute :hours
        attribute :user_id
        belongs_to :user
        scope :approved, -> { where(status: 'approved') }
        scope :full_time, -> { where(hours: 40) }
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

    it "does not refetch ordered, associated objects from a preset variable" do
      ordered_comments = @user_with_included_data.comments.order(Hash['date', 'desc'])
      expect(Comment).to receive(:request).never
      expect(ordered_comments).to be_a(ActiveService::Collection)
    end

    xit "does not refetch the parents models data if they have been fetched before" do
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

    it "fetches data that was cached through has_many if called with parameters" do
      expect(@user_without_included_data.comments.first.object_id).to_not eq @user_without_included_data.comments.where(:foo_id => 1).first.object_id
    end

    it "fetches data that was not included through has_many again after being reset" do
      expect{ @user_without_included_data.comments.reset }.to change{ @user_without_included_data.comments.first.object_id }
    end

    it "fetches data that was not included through has_many again after being reloaded" do
      expect{ @user_without_included_data.comments.reload }.to change{ @user_without_included_data.comments.first.object_id }
    end

    xit "maps an array of included data through has_one" do
      expect(@user_with_included_data.role).to be_a(Role)
      expect(@user_with_included_data.role.object_id).to eq @user_with_included_data.role.object_id
      expect(@user_with_included_data.role.id).to be 1
      expect(@user_with_included_data.role.body).to eq "Admin"
    end

    it "fetches data that was not included through has_one" do
      expect(@user_without_included_data.role).to be_a(Role)
      expect(@user_without_included_data.role.id).to be 2
      expect(@user_without_included_data.role.body).to eq "User"
    end

    it "fetches has_one data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.role.where(:foo_id => 2).id).to be 3
    end

    xit "maps an array of included data through belongs_to" do
      expect(@user_with_included_data.organization).to be_a(Organization)
      expect(@user_with_included_data.organization.id).to be 1
      expect(@user_with_included_data.organization.name).to eq "Bluth Company"
    end

    it "fetches data that was not included through belongs_to" do
      expect(@user_without_included_data.organization).to be_a(Organization)
      expect(@user_without_included_data.organization.id).to be 2
      expect(@user_without_included_data.organization.name).to eq "Bluth Company"
    end

    it "fetches belongs_to data even if it was included, only if called with parameters" do
      expect(@user_with_included_data.organization.where(:foo_id => 1).name).to eq "Bluth Company Foo"
    end

    it "can tell if it has a association" do
      expect(@user_without_included_data.has_association?(:unknown_association)).to be false
      expect(@user_without_included_data.has_association?(:organization)).to be true
    end

    it "fetches the resource corresponding to a named association" do
      expect(@user_without_included_data.get_association(:unknown_association)).to be_nil
      expect(@user_without_included_data.get_association(:organization).name).to eq "Bluth Company"
    end

    it "pass query string parameters when additional arguments are passed" do
      expect(@user_without_included_data.organization.where(:admin => true).name).to eq "Bluth Company (admin)"
      expect(@user_without_included_data.organization.name).to eq "Bluth Company"
    end

    it "fetches data with the specified id when calling find" do
      comment = @user_without_included_data.comments.find(5)
      expect(comment.id).to be 5
    end

    it "'s has_many association responds to #empty?" do
      expect(@user_without_included_data.comments.respond_to?(:empty?)).to be_truthy
      expect(@user_without_included_data.comments).to_not be_empty
    end

    it "'s belongs_to association responds to #nil?" do
      expect(@user_without_included_data.organization.respond_to?(:nil?)).to be_truthy
      expect(@user_without_included_data.organization).to_not be_nil
    end

    xit 'includes has_many relationships in params by default' do
      params = @user_with_included_data.to_params
      expect(params[:comments]).to be_kind_of(Array)
      expect(params[:comments].length).to be 2
    end

    it "fetches ids for has_many association" do
      expect(@user_without_included_data.comments.collect(&:id)).to eq @user_without_included_data.comment_ids
    end

    it "supports scopes on associations" do
      timesheets = @user_without_included_data.timesheets.approved
      expect(timesheets.count).to be 2
      expect(timesheets.first.id).to be 1
    end    

    it "supports multiple scopes on associations" do
      timesheets = @user_without_included_data.timesheets.approved.full_time
      expect(timesheets.count).to be 1
      expect(timesheets.first.hours).to be 40
    end    

    [:create, :save_existing, :destroy].each do |type|
      context "after #{type}" do
        let(:subject) { self.send("user_with_included_data_after_#{type}")}

        xit "maps an array of included data through has_many" do
          expect(subject.comments.first).to be_a(Comment)
          expect(subject.comments.length).to be 1
          expect(subject.comments.first.id).to be 99
          expect(subject.comments.first.body).to eq "Rodríguez, nasibisibusi?"
        end

        xit "maps an array of included data through has_one" do
          expect(subject.role).to be_a(Role)
          expect(subject.role.id).to be 1
          expect(subject.role.body).to eq "Admin"
        end
      end
    end
  end

  context "handling associations with details" do
    before do
      api = ActiveService::API.new :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON        
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
        uses_api api
        attribute :name
        attribute :organization_id
        belongs_to :company, :path => "/organizations/:id", :foreign_key => :organization_id, :data_key => :organization
      end

      spawn_model "Company" do
        uses_api api
        attribute :name
      end

      @user_with_included_data = User.find(1)
      @user_without_included_data = User.find(2)
      @user_with_included_nil_data = User.find(3)
      @user_with_included_data_but_no_fk = User.find(4)
    end

    it "maps an array of included data through belongs_to" do
      expect(@user_with_included_data.company).to be_a(Company)
      expect(@user_with_included_data.company.id).to be 1
      expect(@user_with_included_data.company.name).to eq "Bluth Company Inc."
    end

    it "does not map included data if it’s nil" do
      expect(@user_with_included_nil_data.company).to be_nil
    end

    it "fetches data that was not included through belongs_to" do
      expect(@user_without_included_data.company).to be_a(Company)
      expect(@user_without_included_data.company.id).to be 1
      expect(@user_without_included_data.company.name).to eq "Bluth Company"
    end

    it "does not require foreign key to have nested object" do
      expect(@user_with_included_data_but_no_fk.company.name).to eq "Bluth Company Inc."
    end
  end

  context "object returned by the association method" do
    before do
      api = ActiveService::API.new :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON        
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { :id => 1, :name => "Tobias Fünke" }.to_json] }
          stub.get("/users/1/role") { |env| [200, {}, { :id => 4, :name => "Therapist", :user_id => 1 }.to_json] }
        end
      end

      spawn_model "Role" do
        uses_api api
        belongs_to :user
        def present?
          "of_course"
        end
      end
      spawn_model "User" do
        uses_api api
        has_one :role
      end
    end

    let(:user_with_role) { User.find(1) }
    let(:associated_value) { User.find(1).role }

    subject { user_with_role.role }

    it "doesnt mask the object's basic methods" do
      expect(subject.class).to eq Role
    end

    it "doesnt mask core methods like extend" do
      committer = Module.new
      subject.extend committer
      expect(subject).to be_kind_of committer
    end

    it "can return the association object" do
      expect(subject.association).to be_kind_of ActiveService::Model::Associations::Association
    end

    it "still can call fetch via the association" do
      expect(subject.association.fetch).to eq associated_value
    end

    it "calls missing methods on associated value" do
      expect(subject.present?).to eq "of_course"
    end

    it "can use association methods like where" do
      expect(subject.where(role: 'committer').association.
        params).to include :role
    end

    it "can use association methods like order" do
      expect(subject.order(:name).association.
        params).to include :sort
    end
  end

  context "building and creating association data" do
    before do
      spawn_model "Comment" do
        attribute :body    
        attribute :user_id
        belongs_to :user
      end
      spawn_model "User" do
        has_many :comments
      end
    end

    context "with #build" do
      it "takes the parent primary key" do
        @comment = User.new(:id => 10).comments.build(:body => "Hello!")
        expect(@comment.body).to eq "Hello!"
        expect(@comment.user_id).to be 10
      end
    end

    context "with #create" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.use ActiveService::Middleware::ParseJSON
          builder.use Faraday::Request::UrlEncoded
          builder.adapter :test do |stub|
            stub.get("/users/10") { |env| [200, {}, { :id => 10 }.to_json] }
            stub.post("/comments") { |env| [200, {}, { :id => 1, :body => Faraday::Utils.parse_query(env[:body])['body'], :user_id => Faraday::Utils.parse_query(env[:body])['user_id'].to_i }.to_json] }
            stub.get("/users/10/comments") { |env| [200, {}, [{ :id => 1, :body => "Hello!", :user_id => 10 }].to_json] }
          end
        end

        User.use_api api
        Comment.use_api api
      end

      it "takes the parent primary key and saves the resource" do
        @user = User.find(10)
        @comment = @user.comments.create(:body => "Hello!")
        expect(@comment.id).to be 1
        expect(@comment.body).to eq "Hello!"
        expect(@comment.user_id).to be 10
        expect(@user.comments).to eq [@comment]
      end
    end

    context "with #new" do
      xit "creates nested models from hash attibutes" do
        user = User.new(:name => "vic", :comments => [{:text => "hello"}])
        expect(user.comments.first.text).to eq "hello"
      end

      xit "assigns nested models if given as already constructed objects" do
        bye = Comment.new(:text => "goodbye")
        user = User.new(:name => 'vic', :comments => [bye])
        expect(user.comments.first.text).to eq 'goodbye'
      end
    end
  end
end
