# -*- encoding : utf-8 -*-
module Concerns
  # Handles the administrative metadata.
  module AdminMetadata
    extend ActiveSupport::Concern

    included do
      contains 'adminMetadata', class_name: 'Datastreams::AdminDatastream'

      has_attributes :activity, :workflow_status, :embargo, :embargo_date, :embargo_condition, :access_condition,
                     :copyright, :material_type, :availability, :collection, :type, :external_repository, :validation_status,
                     datastream: 'adminMetadata', :multiple => false

      has_attributes :validation_message, datastream: 'adminMetadata', :multiple => true

      def add_validation_message=(messages)
        self.validation_message=messages
      end
    end
  end
end
