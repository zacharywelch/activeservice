module ActiveService
  module Model
    module Errors
      extend ActiveSupport::Concern

      # Assign resource errors to ActiveModel errors array
      def assign_errors(items)
        errors.clear
        items = self.class.parse(items)
        items.each do |attr, attr_errors|
          attr_errors.each { |error| errors.add(attr, error) }
        end
        assign_associations_errors items
      end

      private

      # Assuming association errors arrive in format as the example below:
      #   class User < ActiveService::Base
      #     has_one :role
      #   end
      #
      #   class Role < ActiveService::Base
      #     attribute :name
      #     belongs_to :user
      #   end
      #
      #   PUT /users/:id with a blank role name returns the following
      #   error format:
      #     { 'role.name' => ["can't be blank"] }
      #
      # This method will assign the errors on the Role association.
      #
      # @private
      def assign_associations_errors(items)
        items = parse_association_errors(items)
        items.each do |association_name, errors|
          get_association(association_name).assign_errors(errors)
        end
      end

      # Extract association errors into standard hash
      #   before:
      #     { 'role.name' => ["can't be blank"] }

      #   after:
      #     { 'role' => { 'name' => ["can't be blank"] } }
      #
      # @private
      def parse_association_errors(items)
        items.select! { |key, _| key.to_s.include?('.') }
        items.each_with_object({}) do |(key, errors), hash|
          association_name, field = key.to_s.split('.', 2)
          if has_association?(association_name)
            hash[association_name] = { field => errors }
          end
        end
      end
    end
  end
end
