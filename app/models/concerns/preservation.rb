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

      contains 'preservationMetadata', class_name: 'Datastreams::PreservationDatastream'

      property :preservation_collection,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_state,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_details,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_modify_date,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_comment,  delegate_to: 'preservationMetadata', :multiple => false
      property :warc_id,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_bitsafety,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_confidentiality,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_initiated_date,  delegate_to: 'preservationMetadata', :multiple => false
      property :file_warc_id, delegate_to: 'preservationMetadata', :multiple => false

      validate :validate_preservation

      before_validation :update_preservation_collection

      def is_preservable
        true
      end

      # Creates a job on the send_to_reservation queue
      def send_to_preservation
        self.preservation_state = PRESERVATION_STATE_INITIATED.keys.first
        self.preservation_details = 'The preservation button has been pushed.'
        self.save
        puts "Sending #{self.class.name + ':' + self.id} to preservation"
        Resque.enqueue(SendToPreservationJob,self.id)
      end

      def update_preservation_collection
        if self.preservation_collection.blank?
          self.preservation_collection = Nokogiri::XML.parse(self.preservationMetadata.content).xpath('fields/preservation_profile/text()').to_s
          self.preservation_collection = 'Undefined' if self.preservation_collection.blank?
        end
        self.preservation_state = PRESERVATION_STATE_NOT_STARTED.keys.first if preservation_state.blank?
        self.preservation_details = 'N/A' if preservation_details.blank?
        if PRESERVATION_CONFIG['preservation_collection'].keys.include? self.preservation_collection
          self.preservation_bitsafety = PRESERVATION_CONFIG['preservation_collection'][self.preservation_collection]['bit_safety']
          self.preservation_confidentiality = PRESERVATION_CONFIG['preservation_collection'][self.preservation_collection]['confidentiality']
        end
        set_preservation_modified_time
      end

      def validate_preservation
        inherit_rights_metadata if self.respond_to? :inherit_rights_metadata
        update_preservation_collection
        if (self.preservation_collection != 'Undefined' && (!PRESERVATION_CONFIG['preservation_collection'].include? self.preservation_collection))
          puts "#{self.preservation_collection} is not an accepted part of #{PRESERVATION_CONFIG['preservation_collection'].keys}"
          errors.add(:preservation_collection,'Ugyldig Bevaringsprofil')
        end
      end

      # Cascades the preservation collection, if it can be cascaded.
      def cascade_preservation_collection
        self.reload
        if self.can_perform_cascading?
          self.cascading_elements.each do |pib|
            pib.preservation_collection = self.preservation_collection
            pib.save
          end
        end
      end

      # Initiates the preservation. If the profile is set to long-term preservation, then a message is created and sent.
      def initiate_preservation
        profile = PRESERVATION_CONFIG['preservation_collection'][self.preservation_collection]
        self.update_preservation_collection

        if profile['yggdrasil'].blank? || profile['yggdrasil'] == 'false'
          self.preservation_state = PRESERVATION_STATE_NOT_LONGTERM.keys.first
          self.preservation_details = 'Not longterm preservation.'
          self.save
        else
          self.preservation_state = PRESERVATION_REQUEST_SEND.keys.first
          puts "#{self.class.name} change to preservation state: #{self.preservation_state}"
          if self.save
            message = create_preservation_message
            send_message_to_preservation(message.to_json)
          else
            raise "Initate_Preservation: Failed to update preservation data"
          end
        end
        self.set_preservation_initiated_time
      end

      #private
      # Delivers the preservation message as a Hash. Needs to be converted into JSON before sending.
      def create_preservation_message
        message = Hash.new
        message['UUID'] = self.uuid
        message['Preservation_profile'] = self.preservationMetadata.preservation_collection.first
        message['Valhal_ID'] = self.id
        message['Model'] = self.class.name

        if self.kind_of?(ContentFile)
          message['File_UUID'] = self.file_uuid

          # Only add the content uri, if the file is not older than the latest preservation initiation date.
          if self.file_warc_id.nil? || self.preservation_initiated_date.nil? || DateTime.parse(self.preservation_initiated_date) <= DateTime.parse(self.last_modified)
            message['file_warc_id'] = self.file_warc_id
            app_url = CONFIG[Rails.env.to_sym][:application_url]
            path = url_for(:controller => 'view_file', :action => 'show', :id =>self.id, :only_path => true)
            message['Content_URI'] = "#{app_url}#{path}"
          end
        end

        unless self.warc_id.nil? || self.warc_id.empty?
          message['warc_id'] = self.warc_id
        end

        metadata = self.create_preservation_message_metadata
        message['metadata'] = metadata
        message
      end

      def set_preservation_modified_time
        self.preservationMetadata.preservation_modify_date = DateTime.now.strftime("%FT%T.%L%:z")
      end

      def set_preservation_initiated_time
        self.preservationMetadata.preservation_initiated_date = DateTime.now.strftime("%FT%T.%L%:z")
      end
    end
  end
end
