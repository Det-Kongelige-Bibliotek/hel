# -*- encoding : utf-8 -*-
require 'resque'
module Concerns
  # The preservation definition which is to be used by all elements.
  # Adds the preservation metadata datastream, and sets up default values.
  module Preservation
    extend ActiveSupport::Concern

    included do
      include ActiveFedora::Callbacks # to be able to define the 'before_validation' method
      include Rails.application.routes.url_helpers

      has_metadata :name => 'preservationMetadata', :type => Datastreams::PreservationDatastream
      has_attributes :preservation_profile, :preservation_state, :preservation_details, :preservation_modify_date,
                     :preservation_comment, :warc_id, :preservation_bitsafety, :preservation_confidentiality,
                     datastream: 'preservationMetadata', :multiple => false

      validate :validate_preservation

      before_validation :update_preservation_profile

      def is_preservable
        true
      end

      # Creates a job on the send_to_reservation queue
      def send_to_preservation
        self.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        self.preservation_details = 'The preservation button has been pushed.'
        self.save
        Resque.enqueue(SendToPreservationJob,self.pid)
      end


      def update_preservation_profile
        self.preservation_profile = 'Undefined' if self.preservation_profile.blank?
        self.preservation_state = PRESERVATION_STATE_NOT_STARTED.keys.first if preservation_state.blank?
        self.preservation_details = 'N/A' if preservation_details.blank?
        if PRESERVATION_CONFIG['preservation_profile'].keys.include? self.preservation_profile
          self.preservation_bitsafety = PRESERVATION_CONFIG['preservation_profile'][self.preservation_profile]['bit_safety']
          self.preservation_confidentiality = PRESERVATION_CONFIG['preservation_profile'][self.preservation_profile]['confidentiality']
        end
        set_preservation_modified_time
      end

      def validate_preservation
        if (self.preservation_profile != 'Undefined' && (!PRESERVATION_CONFIG['preservation_profile'].include? self.preservation_profile))
          errors.add(:preservation_profile,'Ugyldig Bevaringsprofil')
        end
      end


      # Check whether it should be cascading, and also perform the cascading.
      # @param params The parameter from the controller. Contains the parameter for whether the preservation
      # should be cascaded.
      # @param element The element to have stuff cascaded.
      def cascade_preservation
        self.reload
        if self.can_perform_cascading?
          self.cascading_elements.each do |pib|
            pib.preservation_profile = self.preservation_profile
            pib.save
          end
        end
      end


      # Initiates the preservation. If the profile is set to long-term preservation, then a message is created and sent.
      # @param element The element to perform the preservation upon.
      def initiate_preservation(cascade = true)
        profile = PRESERVATION_CONFIG['preservation_profile'][self.preservation_profile]

        if profile['yggdrasil'].blank? || profile['yggdrasil'] == 'false'
          self.preservation_state = PRESERVATION_STATE_NOT_LONGTERM.keys.first
          self.preservation_details = 'Not longterm preservation.'
          self.save
        else
          self.preservation_state = PRESERVATION_REQUEST_SEND.keys.first
          message = create_preservation_message
          puts "saving object #{self.preservation_state}"
          if self.save
            send_message_to_preservation(message)
          else
            raise "Initate_Preservation: Failed to update preservation data"
          end
        end
      end

      private
      def create_preservation_message
        message = Hash.new
        message['UUID'] = self.uuid
        message['Preservation_profile'] = self.preservationMetadata.preservation_profile.first
        message['Valhal_ID'] = self.pid
        message['Model'] = self.class.name

        if self.kind_of?(ContentFile)
          message['File_UUID'] = self.file_uuid
          app_url = CONFIG[Rails.env.to_sym][:application_url]
          path = url_for(:controller => 'view_file', :action => 'show', :pid =>self.pid, :only_path => true)
          message['Content_URI'] = "#{app_url}#{path}"
        end

        metadata = create_message_metadata
        message['metadata'] = metadata

        message.to_json
      end

      # Creates the metadata part of the message.
      # @return The metadata for the element.
      def create_message_metadata
        content = self.create_preservation_message_metadata
        logger.debug("preservation_metadata: <metadata>#{content}</metadata>")
        "<metadata>#{content}</metadata>"
      end

      def set_preservation_modified_time
        self.preservationMetadata.preservation_modify_date = DateTime.now.strftime("%FT%T.%L%:z")
      end
    end
  end
end