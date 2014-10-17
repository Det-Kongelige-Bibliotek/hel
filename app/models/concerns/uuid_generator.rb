module Concerns
  # Include this module if you want your
  # model to have a uuid.
  # Note that you will need to ensure you have a uuid=
  # method and storage solution. This module leaves that
  # responsibility to the including class.
  module UUIDGenerator
    extend ActiveSupport::Concern

    included do
      include ActiveFedora::Callbacks
      include ActiveFedora::Validations

      protected

      validates :uuid, presence: true, length: { minimum: 16, maximum: 64 }
      before_validation :ensure_uuid_method_present, :create_uuid

      # The including class MUST have a uuid method
      # We do not create one here because we assume that
      # different models will store them in different places
      # e.g. a Bibframe identifier field vs a MADS identifier field
      def ensure_uuid_method_present
        return if self.respond_to?(:uuid=)
        fail 'Your class must have a uuid= method present to use this module'
      end

      def create_uuid
        return if uuid.present?
        self.uuid = UUID.new.generate
      end
    end
  end
end
