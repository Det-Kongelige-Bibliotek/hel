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

      property :preservation_profile,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_state,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_details,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_modify_date,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_comment,  delegate_to: 'preservationMetadata', :multiple => false
      property :warc_id,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_bitsafety,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_confidentiality,  delegate_to: 'preservationMetadata', :multiple => false
      property :preservation_initiated_date,  delegate_to: 'preservationMetadata', :multiple => false
      property :file_warc_id, delegate_to: 'preservationMetadata', :multiple => false

      property :import_token, delegate_to: 'preservationMetadata', :multiple => false
      property :import_token_timeout, delegate_to: 'preservationMetadata', :multiple => false
      property :import_state, delegate_to: 'preservationMetadata', :multiple => false

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
        puts "Sending #{self.class.name + ':' + self.id} to preservation"
        Resque.enqueue(SendToPreservationJob,self.id)
      end

      # Sends send
      def send_request_to_import(type, update_id=nil)
        if self.warc_id.blank?
          return false
        end
        # TODO validate update_id (check that there is a preservation update with the given uuid.)
        # TODO validate the preservation profile

        Resque.enqueue(SendRequestToImportFromPreservationJob, self.id, type, update_id)
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
        inherit_rights_metadata if self.respond_to? :inherit_rights_metadata
        update_preservation_profile
        if (self.preservation_profile != 'Undefined' && (!PRESERVATION_CONFIG['preservation_profile'].include? self.preservation_profile))
          puts "#{self.preservation_profile} is not an accepted part of #{PRESERVATION_CONFIG['preservation_profile'].keys}"
          errors.add(:preservation_profile,'Ugyldig Bevaringsprofil')
        end
      end

      # Cascades the preservation profile, if it can be cascaded.
      def cascade_preservation_profile
        self.reload
        if self.can_perform_cascading?
          self.cascading_elements.each do |pib|
            pib.preservation_profile = self.preservation_profile
            pib.save
          end
        end
      end

      # Initiates the preservation. If the profile is set to long-term preservation, then a message is created and sent.
      def initiate_preservation
        profile = PRESERVATION_CONFIG['preservation_profile'][self.preservation_profile]
        self.update_preservation_profile

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

      # Initiates the import from preservation, by creating the message and sending it to
      def initiate_import_from_preservation(type, update)



        profile = PRESERVATION_CONFIG['preservation_profile'][self.preservation_profile]
        self.update_preservation_profile

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
        message['Preservation_profile'] = self.preservationMetadata.preservation_profile.first
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

      # Create a message in the following format:
      # type: FILE
      # uuid: uuid-1234
      # preservation_profile: eternity
      # url: http://valhal.kb.dk:3000/import_file/content_file_uuid
      # warc:
      #     warc_file_id: example.warc
      #     warc_record_id: uuid-1234-warc-record
      #     warc_offset: 87539319
      #     warc_record_size: 1729
      # security:
      #     checksum: d41d8cd98f00b204e9800998ecf8427e
      #     token: THIS_IS_A_TOKEN
      #     token_timeout: Tue Aug 11 12:29:46 CEST 2015
      def create_import_from_preservation_message(type, update_id=nil)
        message = Hash.new
        message['type'] = type
        message['uuid'] = self.uuid
        message['preservation_profile'] = self.preservationMetadata.preservation_profile.first
        message['url'] = url_for(:controller => 'view_file', :action => 'import_from_preservation')

        # if self.kind_of?(ContentFile)
        #   message['File_UUID'] = self.file_uuid
        #
        #   # Only add the content uri, if the file is not older than the latest preservation initiation date.
        #   if self.file_warc_id.nil? || self.preservation_initiated_date.nil? || DateTime.parse(self.preservation_initiated_date) <= DateTime.parse(self.last_modified)
        #     message['file_warc_id'] = self.file_warc_id
        #     app_url = CONFIG[Rails.env.to_sym][:application_url]
        #     path = url_for(:controller => 'view_file', :action => 'show', :id =>self.id, :only_path => true)
        #     message['Content_URI'] = "#{app_url}#{path}"
        #   end
        # end
        #
        # unless self.warc_id.nil? || self.warc_id.empty?
        #   message['warc_id'] = self.warc_id
        # end
        #
        # metadata = self.create_preservation_message_metadata
        # message['metadata'] = metadata
        message
      end
    end
  end
end
