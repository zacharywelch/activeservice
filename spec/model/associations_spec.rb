# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Associations do
  context "setting associations without options" do
    before { spawn_model "User" }
    subject { User.associations }

    context "single has_many association" do
      let(:association) do
        {
          name: :comments,
          data_key: :comments,
          default: [],
          class_name: "Comment",
          path: nil,
          inverse_of: nil
        }
      end

      before { User.has_many :comments }
      its([:has_many]) { should eql [association] }
    end

    context "multiple has_many associations" do
      let(:comments_association) do
        {
          name: :comments,
          data_key: :comments,
          default: [],
          class_name: "Comment",
          path: nil,
          inverse_of: nil
        }
      end

      let(:posts_association) do
        {
          name: :posts,
          data_key: :posts,
          default: [],
          class_name: "Post",
          path: nil,
          inverse_of: nil
        }
      end

      before do
        User.has_many :comments
        User.has_many :posts
      end
      its([:has_many]) { should eql [comments_association, posts_association] }
    end

    context "single has_and_belongs_to_many association" do
      let(:association) do
        {
          name: :roles,
          data_key: :roles,
          default: [],
          class_name: "Role",
          path: nil
        }
      end

      before { User.has_and_belongs_to_many :roles }
      its([:has_and_belongs_to_many]) { should eql [association] }
    end

    context "multiple has_and_belongs_to_many associations" do
      let(:roles_association) do
        {
          name: :roles,
          data_key: :roles,
          default: [],
          class_name: "Role",
          path: nil
        }
      end

      let(:groups_association) do
        {
          name: :groups,
          data_key: :groups,
          default: [],
          class_name: "Group",
          path: nil
        }
      end

      before do
        User.has_and_belongs_to_many :roles
        User.has_and_belongs_to_many :groups
      end

      its([:has_and_belongs_to_many]) { should eql [roles_association, groups_association] }
    end

    context "single has_one association" do
      let(:association) do
        {
          name: :category,
          data_key: :category,
          default: nil,
          class_name: "Category",
          path: "/category"
        }
      end

      before { User.has_one :category }
      its([:has_one]) { should eql [association] }
    end

    context "multiple has_one associations" do
      let(:category_association) do
        {
          name: :category,
          data_key: :category,
          default: nil,
          class_name: "Category",
          path: "/category"
        }
      end

      let(:role_association) do
        {
          name: :role,
          data_key: :role,
          default: nil,
          class_name: "Role",
          path: "/role"
        }
      end

      before do
        User.has_one :category
        User.has_one :role
      end

      its([:has_one]) { should eql [category_association, role_association] }
    end

    context "single belongs_to association" do
      let(:association) do
        {
          name: :organization,
          data_key: :organization,
          default: nil,
          class_name: "Organization",
          foreign_key: "organization_id",
          path: "/organizations/:id"
        }
      end

      before { User.belongs_to :organization }
      its([:belongs_to]) { should eql [association] }
    end

    context "multiple belongs_to association" do
      let(:organization_association) do
        {
          name: :organization,
          data_key: :organization,
          default: nil,
          class_name: "Organization",
          foreign_key: "organization_id",
          path: "/organizations/:id"
        }
      end

      let(:family_association) do
        {
          name: :family,
          data_key: :family,
          default: nil,
          class_name: "Family",
          foreign_key: "family_id",
          path: "/families/:id"
        }
      end

      before do
        User.belongs_to :organization
        User.belongs_to :family
      end

      its([:belongs_to]) { should eql [organization_association, family_association] }
    end
  end

  context "setting associations with options" do
    before { spawn_model "User" }
    subject { User.associations }

    context "in base class" do
      context "single has_many association" do
        let(:association) do
          {
            name: :comments,
            data_key: :user_comments,
            default: {},
            class_name: "Post",
            path: nil,
            inverse_of: :admin
          }
        end

        before do
          User.has_many :comments, class_name: "Post", inverse_of: :admin,
                                   data_key: :user_comments, default: {}
        end
        its([:has_many]) { should eql [association] }
      end

      context "single has_and_belongs_to_many association" do
        let(:association) do
          {
            name: :roles,
            data_key: :user_roles,
            default: {},
            class_name: "Permission",
            path: nil
          }
        end

        before do
          User.has_and_belongs_to_many :roles, class_name: "Permission",
                                               data_key: :user_roles,
                                               default: {}
        end
        its([:has_and_belongs_to_many]) { should eql [association] }
      end

      context "single has_one association" do
        let(:association) do
          {
            name: :category,
            data_key: :topic,
            default: nil,
            class_name: "Topic",
            foreign_key: "topic_id",
            path: "/category"
          }
        end

        before do
          User.has_one :category, class_name: "Topic", foreign_key: "topic_id",
                                  data_key: :topic, default: nil
        end
        its([:has_one]) { should eql [association] }
      end

      context "single belongs_to association" do
        let(:association) do
          {
            name: :organization,
            data_key: :org,
            default: true,
            class_name: "Business",
            foreign_key: "org_id",
            path: "/organizations/:id"
          }
        end

        before do
          User.belongs_to :organization, class_name: "Business",
                                         foreign_key: "org_id", data_key: :org,
                                         default: true
        end
        its([:belongs_to]) { should eql [association] }
      end
    end

    context "in parent class" do
      let(:association) do
        {
          name: :comments,
          data_key: :comments,
          default: [],
          class_name: "Post",
          path: nil,
          inverse_of: nil
        }
      end

      before { User.has_many :comments, class_name: "Post" }

      describe "associations accessor" do
        subject { Class.new(User).associations }
        its(:object_id) { should_not eql User.associations.object_id }
        its([:has_many]) { should eql [association] }
      end
    end
  end

  describe "#has_association?" do
    before do
      spawn_model "User" do
        attribute :name
        has_many :comments
      end
    end

    subject { User.new }

    it { should have_association(:comments) }
    it { should_not have_association(:foo) }
  end

  describe "#get_association" do
    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Lindsay Fünke" }.to_json] }
          stub.get("/users/1/comments") { |env| [200, {}, [{ id: 1, body: "They're having a FIRESALE?" }].to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_many :comments
      end

      spawn_model "Comment" do
        uses_api api
        attribute :body
      end
    end

    let(:user) { User.find(1) }

    it "fetches the association" do
      expect(user.get_association(:comments).length).to be 1
      expect(user.get_association(:comments).first.id).to be 1
    end
  end

  describe "#find" do
    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1 }.to_json] }
          stub.get("/users/1/comments/2") { |env| [200, {}, { id: 2 }.to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        has_many :comments
      end

      spawn_model "Comment" do
        uses_api api
      end
    end

    let(:user) { User.find(1) }

    it "fetches data with the specified id when calling find" do
      expect(user.comments.find(2).id).to be 2
    end
  end

  describe "#where" do

    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Lindsay Fünke", organization_id: 1 }.to_json] }
          stub.get("/organizations/1") do |env|
            if env[:params]["admin"] == "true"
              [200, {}, { id: 2, name: "Bluth Company (admin)" }.to_json]
            else
              [200, {}, { id: 2, name: "Bluth Company" }.to_json]
            end
          end
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        attribute :organization_id
        belongs_to :organization
      end

      spawn_model "Organization" do
        uses_api api
        attribute :name
      end
    end

    let(:user) { User.find(1) }

    it "passes query string parameters" do
      expect(user.organization.where(admin: true).name).to eq "Bluth Company (admin)"
      expect(user.organization.name).to eq "Bluth Company"
    end
  end

  context "with scopes" do

    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Tobias Fünke" }.to_json] }
          stub.get("/users/1/timesheets?status=approved&hours=40") { |env| [200, {}, [{ id: 2, status: 'approved', hours: 40, user_id: 1 }].to_json] }
          stub.get("/users/1/timesheets?status=approved") { |env| [200, {}, [{ id: 1, status: 'approved', hours: 20, user_id: 1 }, { id: 2, status: 'approved', hours: 40, user_id: 1 }].to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_many :timesheets
      end

      spawn_model "Timesheet" do
        uses_api api
        attribute :status
        attribute :hours
        attribute :user_id
        belongs_to :user
        scope :approved, -> { where(status: 'approved') }
        scope :full_time, -> { where(hours: 40) }
      end
    end

    let(:user) { User.find(1) }

    it "supports scopes on associations" do
      timesheets = user.timesheets.approved
      expect(timesheets.count).to be 2
      expect(timesheets.first.id).to be 1
    end

    it "supports multiple scopes on associations" do
      timesheets = user.timesheets.approved.full_time
      expect(timesheets.count).to be 1
      expect(timesheets.first.hours).to be 40
    end

    it "chains scopes using one request" do
      expect(Timesheet).to receive(:request).once.and_call_original
      timesheets = user.timesheets.approved.full_time
      expect(timesheets.count).to be 1
    end
  end

  context "has_many associations without options" do

    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Lindsay Fünke" }.to_json] }
          stub.get("/users/1/comments") { |env| [200, {}, [{ id: 1, body: "They're having a FIRESALE?" }, { id: 2, body: "Is this the tiny town from Footloose?" }].to_json] }
          stub.get("/users/1/posts") { |env| [200, {}, [{ id: 1, body: 'blogging stuff', admin_id: 1, approved: true }, { id: 2, body: 'personal stuff', admin_id: 1, approved: false }].to_json] }

          stub.get("/users/2") { |env| [200, {}, { id: 2, name: "Tobias Fünke", comments: [{ id: 3, body: "Tobias, you blow hard!", user_id: 2 }, { id: 4, body: "I wouldn't mind kissing that man between the cheeks, so to speak", user_id: 2 }] }.to_json] }
          stub.get("/users/2/comments") { |env| [200, {}, [{ id: 4, body: "They're having a FIRESALE?", user_id: 2 }].to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_many :comments
        has_many :posts, inverse_of: :admin
      end

      spawn_model "Comment" do
        uses_api api
        attribute :body
        attribute :user_id
        belongs_to :user
      end

      spawn_model "Post" do
        uses_api api
        attribute :body
        attribute :admin_id
        belongs_to :admin, class_name: 'User'
      end
    end

    let(:user) { User.find(1) }
    let(:user_with_comments) { User.find(2) }

    it "maps an array of included data" do
      expect(user_with_comments.comments.first).to be_a(Comment)
      expect(user_with_comments.comments.length).to be 2
      expect(user_with_comments.comments.first.id).to be 3
      expect(user_with_comments.comments.first.body).to eq "Tobias, you blow hard!"
    end

    xit "doesn't refetch parents model data" do
      expect(user_with_comments.comments.first.user.object_id).to eq user_with_comments.object_id
    end

    it "uses inverse_of key to set the parent model" do
      expect(user.posts.first.admin.object_id).to eq user.object_id
    end

    it "fetches included data if called with parameters" do
      expect(user_with_comments.comments.where(foo_id: 1).length).to be 1
    end

    it "fetches cached data if called with parameters" do
      expect(user.comments.first.object_id).to_not eq user.comments.where(foo_id: 1).first.object_id
    end

    it "doesn't fetch cached data if called without parameters" do
      expect(Comment).to receive(:request).once.and_call_original
      ordered_comments = user.comments.order(date: :desc)
      expect(ordered_comments.first.object_id).to eq ordered_comments.first.object_id
    end

    it "fetches data that was not included" do
      expect(user.comments.first).to be_a(Comment)
      expect(user.comments.length).to be 2
      expect(user.comments.first.id).to be 1
      expect(user.comments.first.body).to eq "They're having a FIRESALE?"
    end

    it "fetches data that was not included only once" do
      expect(user.comments.first.object_id).to eq user.comments.first.object_id
    end

    it "fetches data again after being reloaded" do
      expect { user.comments.reload }.to change { user.comments.first.object_id }
    end

    it "responds to #empty?" do
      expect(user.comments).to respond_to(:empty?)
      expect(user.comments).to_not be_empty
    end

    xit "includes relationship in params by default" do
      params = user_with_comments.to_params
      expect(params[:comments]).to be_kind_of(Array)
      expect(params[:comments].length).to be 2
    end

    it "fetches ids" do
      expect(user.comments.collect(&:id)).to eq user.comment_ids
    end

    [:create, :save_existing, :destroy].each do |type|
      context "after #{type}" do
        let(:subject) { self.send("user_with_comments_after_#{type}")}

        xit "maps an array of included data" do
          expect(subject.comments.first).to be_a(Comment)
          expect(subject.comments.length).to be 1
          expect(subject.comments.first.id).to be 99
          expect(subject.comments.first.body).to eq "Rodríguez, nasibisibusi?"
        end
      end
    end
  end

  context "belongs_to associations without options" do

    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Lindsay Fünke", organization_id: 1 }.to_json] }
          stub.get("/organizations/1") { |env| [200, {}, { id: 1, name: "Bluth Company Foo" }.to_json] }

          stub.get("/users/2") { |env| [200, {}, { id: 2, name: "Tobias Fünke", organization_id: 1, organization: { id: 1, name: "Bluth Company" } }.to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        attribute :organization_id
        belongs_to :organization
      end

      spawn_model "Organization" do
        uses_api api
        attribute :name
      end
    end

    let(:user) { User.find(1) }
    let(:user_with_organization) { User.find(2) }

    it "maps an array of included data through belongs_to" do
      expect(user_with_organization.organization).to be_a(Organization)
      expect(user_with_organization.organization.id).to be 1
      expect(user_with_organization.organization.name).to eq "Bluth Company"
    end

    it "fetches data that was not included" do
      expect(user.organization).to be_a(Organization)
      expect(user.organization.id).to be 1
      expect(user.organization.name).to eq "Bluth Company Foo"
    end

    it "fetches included data if called with parameters" do
      expect(user_with_organization.organization.where(foo_id: 1).name).to eq "Bluth Company Foo"
    end

    it "responds to #nil?" do
      expect(user.organization).to respond_to(:nil?)
      expect(user.organization).to_not be_nil
    end

    it "fetches parent model data only once" do
      user = User.new(id: 1, organization_id: 1)
      expect(user.organization.object_id).to eq user.organization.object_id
    end

    it "fetches cached parent model data if called with parameters" do
      user = User.new(id: 1, organization_id: 1)
      expect(user.organization.object_id).to_not eq user.organization.where(a: 2).object_id
    end
  end

  context "has_one associations without options" do

    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Tobias Fünke" }.to_json] }
          stub.get("/users/1/role") { |env| [200, {}, { id: 1, name: "User" }.to_json] }

          stub.get("/users/2") { |env| [200, {}, { id: 2, name: "Lindsay Fünke", role: { id: 2, name: "Admin" } }.to_json] }
          stub.get("/users/2/role") { |env| [200, {}, { id: 3, name: "User" }.to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_one :role
      end

      spawn_model "Role" do
        uses_api api
        attribute :name
      end
    end

    let(:user) { User.find(1) }
    let(:user_with_role) { User.find(2) }

    it "maps an array of included data through has_one" do
      expect(user_with_role.role).to be_a(Role)
      expect(user_with_role.role.object_id).to eq user_with_role.role.object_id
      expect(user_with_role.role.id).to be 2
      expect(user_with_role.role.name).to eq "Admin"
    end

    it "fetches data that was not included" do
      expect(user.role).to be_a(Role)
      expect(user.role.id).to be 1
      expect(user.role.name).to eq "User"
    end

    it "fetches included data if called with parameters" do
      expect(user_with_role.role.where(foo_id: 1).id).to be 3
    end

    [:create, :save_existing, :destroy].each do |type|
      context "after #{type}" do
        let(:subject) { self.send("user_with_role_after_#{type}")}

        xit "maps an array of included data" do
          expect(subject.role).to be_a(Role)
          expect(subject.role.id).to be 1
          expect(subject.role.body).to eq "Admin"
        end
      end
    end
  end

  context "has_and_belongs_to_many associations without options" do

    before do
      api = ActiveService::API.new url: "https://api.example.com" do |conn|
        conn.use ActiveService::Middleware::ParseJSON
        conn.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Tobias Fünke" }.to_json] }
          stub.get("/users/1/groups") { |env| [200, {}, [{ id: 1, name: "Blue Man Group" }, { id: 2, name: "Bluth Company" }].to_json] }

          stub.get("/users/2") { |env| [200, {}, { id: 2, name: "Lindsay Fünke", groups: [{ id: 3, name: "Blue Man Group" }, { id: 4, name: "Bluth Company" }] }.to_json] }
          stub.get("/users/2/groups") { |env| [200, {}, [{ id: 3, name: "Blue Man Group" }].to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_and_belongs_to_many :groups
      end

      spawn_model "Group" do
        uses_api api
        attribute :name
      end
    end

    let(:user) { User.find(1) }
    let(:user_with_groups) { User.find(2) }

    it "maps an array of included data" do
      expect(user_with_groups.groups.first).to be_a(Group)
      expect(user_with_groups.groups.length).to be 2
      expect(user_with_groups.groups.first.id).to be 3
      expect(user_with_groups.groups.first.name).to eq "Blue Man Group"
    end

    it "fetches data that was not included" do
      expect(user.groups.first).to be_a(Group)
      expect(user.groups.length).to be 2
      expect(user.groups.first.id).to be 1
      expect(user.groups.first.name).to eq "Blue Man Group"
    end

    it "fetches included data if called with parameters" do
      expect(user_with_groups.groups.where(foo_id: 1).length).to be 1
    end

    it "fetches cached data if called with parameters" do
      expect(user.groups.first.object_id).to_not eq user.groups.where(foo_id: 1).first.object_id
    end

    it "fetches data that was not included only once" do
      expect(user.groups.first.object_id).to eq user.groups.first.object_id
    end

    it "responds to #empty?" do
      expect(user.groups).to respond_to(:empty?)
      expect(user.groups).to_not be_empty
    end

    it "fetches ids" do
      expect(user.groups.collect(&:id)).to eq user.group_ids
    end
  end

  context "associations with options" do
    before do
      api = ActiveService::API.new url: "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Tobias Fünke", organization_id: 1 }.to_json] }
          stub.get("/users/2") { |env| [200, {}, { id: 2, name: "Lindsay Fünke", organization_id: 1, organization: { id: 1, name: "Bluth Company Inc." } }.to_json] }
          stub.get("/users/3") { |env| [200, {}, { id: 3, name: "Lindsay Fünke", organization: nil }.to_json] }
          stub.get("/users/4") { |env| [200, {}, { id: 4, name: "Tobias Fünke", organization: { id: 1, name: "Bluth Company Inc." } }.to_json] }
          stub.get("/companies/1") { |env| [200, {}, { :id => 1, :name => "Bluth Company" }.to_json] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        attribute :organization_id
        belongs_to :company, path: "/organizations/:id",
                             foreign_key: :organization_id,
                             data_key: :organization
      end

      spawn_model "Company" do
        uses_api api
        attribute :name
      end
    end

    let(:user) { User.find(1) }
    let(:user_with_organization) { User.find(2) }
    let(:user_with_nil_organization) { User.find(3) }
    let(:user_with_organization_but_no_fk) { User.find(4) }

    it "maps an array of included data through belongs_to" do
      expect(user_with_organization.company).to be_a(Company)
      expect(user_with_organization.company.id).to be 1
      expect(user_with_organization.company.name).to eq "Bluth Company Inc."
    end

    it "maps nil data to nil" do
      expect(user_with_nil_organization.company).to be_nil
    end

    it "fetches data that was not included" do
      expect(user.company).to be_a(Company)
      expect(user.company.id).to be 1
      expect(user.company.name).to eq "Bluth Company"
    end

    it "maps included data without foreign key" do
      expect(user_with_organization_but_no_fk.company.name).to eq "Bluth Company Inc."
    end
  end

  context "object returned by the association method" do
    before do
      api = ActiveService::API.new url: "https://api.example.com" do |builder|
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

  context "building and creating has_many associations" do

    before do
      api = ActiveService::API.setup url: "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1 }.to_json] }
          stub.post("/users/1/comments") { |env| [200, {}, { id: 1, body: Faraday::Utils.parse_query(env[:body])['body'], user_id: Faraday::Utils.parse_query(env[:body])['user_id'].to_i }.to_json] }
          stub.get("/users/1/comments") { |env| [200, {}, [{ id: 1, body: "Hello!", user_id: 1 }].to_json] }
        end
      end

      spawn_model "User" do
        use_api api
        has_many :comments
      end

      spawn_model "Comment" do
        use_api api
        attribute :body
        attribute :user_id
        belongs_to :user
      end
    end

    let(:user) { User.new(id: 1) }

    describe "#build" do

      it "takes the parent primary key" do
        comment = user.comments.build(body: "Hello!")
        expect(comment.body).to eq "Hello!"
        expect(comment.user_id).to be 1
      end

      it "posts to the nested resource" do
        comment = user.comments.build(body: "Hello!")
        comment.save
        expect(comment).to be_persisted
      end
    end

    describe "#create" do

      it "takes the parent primary key" do
        comment = user.comments.create(body: "Hello!")
        expect(comment.id).to be 1
        expect(comment.body).to eq "Hello!"
        expect(comment.user_id).to be 1
      end

      it "posts to the nested resource" do
        comment = user.comments.create(body: "Hello!")
        expect(comment.id).to be 1
        expect(comment.body).to eq "Hello!"
        expect(user.comments).to eq [comment]
      end
    end

    describe "#new" do

      it "creates nested models from hash attibutes" do
        user = User.new(name: "vic", comments: [{ body: "hello" }])
        expect(user.comments.first.body).to eq "hello"
      end

      it "assigns nested models if given as already constructed objects" do
        bye = Comment.new(body: "goodbye")
        user = User.new(name: "vic", comments: [bye])
        expect(user.comments.first.body).to eq "goodbye"
      end
    end
  end

  context "building and creating has_and_belongs_to_many associations" do

    before do
      api = ActiveService::API.setup url: "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.use Faraday::Request::UrlEncoded
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| [200, {}, { id: 1 }.to_json] }
          stub.post("/users/1/roles") { |env| [200, {}, { id: 1, name: Faraday::Utils.parse_query(env[:body])['name'] }.to_json] }
          stub.get("/users/1/roles") { |env| [200, {}, [{ id: 1, name: "admin" }].to_json] }
        end
      end

      spawn_model "User" do
        use_api api
        has_and_belongs_to_many :roles
      end

      spawn_model "Role" do
        use_api api
        attribute :name
      end
    end

    let(:user) { User.new(id: 1) }

    describe "#build" do

      it "posts to the nested resource" do
        role = user.roles.build(name: "admin")
        role.save
        expect(role).to be_persisted
      end
    end

    describe "#create" do

      it "posts to the nested resource" do
        role = user.roles.create(name: "admin")
        expect(role.id).to be 1
        expect(role.name).to eq "admin"
        expect(user.roles).to eq [role]
      end
    end

    describe "#new" do
      it "creates nested models from hash attibutes" do
        user = User.new(name: "vic", roles: [{ name: "admin" }])
        expect(user.roles.first.name).to eq "admin"
      end

      it "assigns nested models if given as already constructed objects" do
        admin = Role.new(name: "admin")
        user = User.new(name: "vic", roles: [admin])
        expect(user.roles.first.name).to eq "admin"
      end
    end
  end
end
