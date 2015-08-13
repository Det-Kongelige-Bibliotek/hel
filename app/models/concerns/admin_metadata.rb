# -*- encoding : utf-8 -*-
module Concerns
  # Handles the administrative metadata.
  module AdminMetadata
    extend ActiveSupport::Concern

    included do
      contains 'adminMetadata', class_name: 'Datastreams::AdminDatastream'

      #has_attributes :activity, :workflow_status, :embargo, :embargo_date, :embargo_condition, :access_condition,
      #               :copyright, :material_type, :availability, :collection, :type, :external_repository, :validation_status,
      #               :ophavsret_status
      #               datastream: 'adminMetadata', :multiple => false
      property :activity,  delegate_to: 'adminMetadata', :multiple => false
      property :workflow_status,  delegate_to: 'adminMetadata', :multiple => false
      property :embargo,  delegate_to: 'adminMetadata', :multiple => false
      property :embargo_date,  delegate_to: 'adminMetadata', :multiple => false
      property :embargo_condition,  delegate_to: 'adminMetadata', :multiple => false
      property :access_condition,  delegate_to: 'adminMetadata', :multiple => false
      property :copyright,  delegate_to: 'adminMetadata', :multiple => false
      property :material_type,  delegate_to: 'adminMetadata', :multiple => false
      property :availability,  delegate_to: 'adminMetadata', :multiple => false
      property :collection,  delegate_to: 'adminMetadata', :multiple => true
      property :type,  delegate_to: 'adminMetadata', :multiple => false
      property :external_repository,  delegate_to: 'adminMetadata', :multiple => false
      property :validation_status,  delegate_to: 'adminMetadata', :multiple => false
      property :copyright_status, delegate_to: 'adminMetadata', :multiple => false

      property :validation_message,  delegate_to: 'adminMetadata', :multiple => true
      property :dissemination_profiles,  delegate_to: 'adminMetadata', :multiple => true

      def add_validation_message=(messages)
        self.validation_message=messages
      end
    end
  end
end
