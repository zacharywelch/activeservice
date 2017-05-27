# encoding: utf-8
require File.join(File.dirname(__FILE__), '../spec_helper.rb')

describe ActiveService::Model::Errors do

  describe 'assign_errors' do
    context 'when response returns validation errors' do
      before do
        api = ActiveService::API.setup url: 'https://api.example.com' do |builder|
          builder.use Faraday::Request::UrlEncoded
          builder.use ActiveService::Middleware::ParseJSON
          builder.adapter :test do |stub|
            stub.get('/users/1') { |env| ok! id: 1, email: 'tfunke@example.com' }
            stub.put('/users/1') { |env| error! email: ['is invalid'] }
          end
        end

        spawn_model :User do
          uses_api api
          attribute :email
        end
      end

      it 'assigns errors to user object' do
        user = User.find(1)
        user.update_attributes(email: 'invalid@email')
        expect(user.errors.count).to be 1
      end
    end
  end

  describe 'assign_associations_errors' do
    context 'when response returns validation errors' do
      context 'with single has_one association' do
        context 'when has_one is nil' do
          before do
            api = ActiveService::API.setup url: 'https://api.example.com' do |builder|
              builder.use Faraday::Request::UrlEncoded
              builder.use ActiveService::Middleware::ParseJSON
              builder.adapter :test do |stub|
                stub.get('/users/1') { |env| ok! id: 1, email: 'test@example.com', role: nil }
                stub.put('/users/1') { |env| error! 'role.name' => ["can't be blank"] }
              end
            end

            spawn_model :User do
              uses_api api
              attribute :email
              has_one :role
            end

            spawn_model :Role do
              attribute :name
              belongs_to :user
            end
          end

          it 'assigns errors to user and role objects' do
            user = User.find(1)
            user.update_attributes(email: 'new@example.com', role: { name: '' })
            expect(user.errors.count).to be 1
            expect(user.role.errors.count).to be 1
          end
        end

        context 'when has_one is not nil' do
          before do
            api = ActiveService::API.setup url: 'https://api.example.com' do |builder|
              builder.use Faraday::Request::UrlEncoded
              builder.use ActiveService::Middleware::ParseJSON
              builder.adapter :test do |stub|
                stub.get('/users/1') { |env| ok! id: 1, email: 'test@example.com', role: { name: 'admin' } }
                stub.put('/users/1') { |env| error! 'role.name' => ["can't be blank"] }
              end
            end

            spawn_model :User do
              uses_api api
              attribute :email
              has_one :role
            end

            spawn_model :Role do
              attribute :name
              belongs_to :user
            end
          end

          it 'assigns errors to user and role objects' do
            user = User.find(1)
            user.update_attributes(email: 'new@example.com', role: { name: '' })
            expect(user.errors.count).to be 1
            expect(user.role.errors.count).to be 1
          end
        end
      end

      context "with multiple has_one associations" do
        before do
          api = ActiveService::API.setup url: 'https://api.example.com' do |builder|
            builder.use Faraday::Request::UrlEncoded
            builder.use ActiveService::Middleware::ParseJSON
            builder.adapter :test do |stub|
              stub.get('/users/1') { |env| ok! id: 1, email: 'test@example.com', role: { name: 'admin' }, address: { street: '123 St' } }
              stub.put('/users/1') { |env| error! 'role.name' => ["can't be blank"], 'address.street' => ["can't be blank"] }
            end
          end

          spawn_model :User do
            uses_api api
            attribute :email
            has_one :role
            has_one :address
          end

          spawn_model :Role do
            attribute :name
            belongs_to :user
          end

          spawn_model :Address do
            attribute :street
            belongs_to :user
          end
        end

        it 'assigns errors to user, role and address objects' do
          user = User.find(1)
          user.update_attributes(email: 'new@example.com',
                                 role: { name: '' },
                                 address: { street: '' })
          expect(user.errors.count).to be 2
          expect(user.role.errors.count).to be 1
          expect(user.address.errors.count).to be 1
        end
      end
    end

    context 'with nested has_one association' do
      before do
        api = ActiveService::API.setup url: 'https://api.example.com' do |builder|
          builder.use Faraday::Request::UrlEncoded
          builder.use ActiveService::Middleware::ParseJSON
          builder.adapter :test do |stub|
            stub.get('/invoices/1') { |env| ok! id: 1, number: '1234', contact: { email: 'test@test.com', address: { street: '123 St' } } }
            stub.put('/invoices/1') { |env| error! 'contact.address.street' => ["can't be blank"] }
          end
        end

        spawn_model :Invoice do
          uses_api api
          attribute :number
          has_one :contact
        end

        spawn_model :Contact do
          attribute :email
          belongs_to :invoice
          has_one :address
        end

        spawn_model :Address do
          attribute :street
          belongs_to :contact
        end
      end

      it 'assigns errors to invoice, contact and address objects' do
        invoice = Invoice.find(1)
        invoice.update_attributes(number: '123', contact: { email: 'test@test.com', address: { street: '' } })
        expect(invoice.errors.count).to be 1
        expect(invoice.contact.errors.count).to be 1
        expect(invoice.contact.address.errors.count).to be 1
      end
    end
  end
end

