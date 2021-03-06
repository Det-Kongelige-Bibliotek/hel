# -*- encoding : utf-8 -*-

# The helper methods for preservation.
# Provides methods for managing the preservation metadata, etc.
module PreservationHelper
  include MqHelper # methods: send_message_to_preservation

  # Updates the preservation state metadata from the controller.
  # Handles both the preservation element and the update element.
  # Expected to receive parameters:
  # params[:preservation][:preservation_state]
  # params[:preservation][:preservation_details]
  # params[:preservation][:warc_id]
  # params[:preservation][:file_warc_id]
  # params[:update][:date]
  # params[:update][:uuid]
  # params[:update][:file_uuid]
  # params[:update][:warc_id]
  # params[:update][:file_warc_id]
  # @param params The parameters from the controller.
  # @param element The element to have its preservation settings updated.
  # @return Whether the preservation metadata has successfully been updated.
  def update_preservation_metadata_for_element(params, element)
    can_update_preservation_state?(element.preservation_state)

    if set_preservation_metadata(params['preservation'], params['update'], element)
      # puts "Preservation metadata updated successfully for #{element}"
      true
    else
      puts "Failed to update preservation metadata for #{element}"
      false
    end
  end

  # Updates the preservation import state metadata for an element
  # Expected to receive parameters:
  # params[:response][:state]
  # params[:response][:detail]
  # params[:response][:date]
  # @param params The parameters
  # @param element The element to have its preservation settings updated.
  # @return Whether the preservation metadata has successfully been updated.
  def update_preservation_import_metadata_for_element(params, element)
    can_update_preservation_import_state?(element.import_state)

    if set_preservation_import_metadata(params['response'], element)
      puts "Preservation metadata updated successfully for #{element}"
      true
    else
      puts "Failed to update preservation metadata for #{element}"
      false
    end
  end

  # Updates the preservation date to this exact point in time.
  # The date has to be formatted explicitly to include the milli/micro/nano-seconds.
  # E,g, 2013-10-08T11:02:00.240+02:00
  # @param element The element to have its preservation date updated.
  def set_preservation_modified_time(element)
    element.preservationMetadata.preservation_modify_date = DateTime.now.strftime("%FT%T.%L%:z")
  end

  private

  # Updates the preservation state and details for a given element (e.g. a basic_files, a instance, a work, etc.)
  # The preservation state is expected to be among the Constants::PRESERVATION_STATES, a warning will be issued if not.
  # @param metadata The hash with preservation metadata to be updated.
  # @param update The hash with preservation update metadata to be updated (only regarding update-preservations, not initial preservations)
  # @param element The element to has its preservation state updated.
  # @return Whether the update was successful. Or just false, if no metadata is provided.
  def set_preservation_metadata(metadata, update, element)
    unless (metadata && (!metadata.empty?) || (update && !update.empty?))
      puts "No metadata for updating element with: #{metadata} or #{update}"
      return false
    end

    updated = false

    unless (metadata['preservation_state'].blank? || metadata['preservation_state'] == element.preservationMetadata.preservation_state.first)
      updated = true
      puts "Undefined preservation state #{metadata['preservation_state']} not among the defined ones: #{PRESERVATION_STATES.keys.to_s}" unless PRESERVATION_STATES.keys.include? metadata['preservation_state']
      element.preservationMetadata.preservation_state = metadata['preservation_state']
    end

    unless (metadata['preservation_details'].blank? || metadata['preservation_details'] == element.preservationMetadata.preservation_details.first)
      updated = true
      element.preservationMetadata.preservation_details = metadata['preservation_details']
    end

    unless (metadata['warc_id'].blank? || metadata['warc_id'] == element.preservationMetadata.warc_id.first)
      updated = true
      element.preservationMetadata.warc_id = metadata['warc_id']
      unless metadata['warc_offset'].blank?
        element.preservationMetadata.warc_offset = metadata['warc_offset']
      end
    end

    unless (metadata['file_warc_id'].blank? || metadata['file_warc_id'] == element.preservationMetadata.file_warc_id.first)
      updated = true
      element.preservationMetadata.file_warc_id = metadata['file_warc_id']
      unless metadata['file_warc_offset'].blank?
        element.preservationMetadata.file_warc_offset = metadata['file_warc_offset']
      end
    end

    if update && !update.empty?
      # puts "Preservation update for #{element} with #{update}"
      element.preservationMetadata.insert_update(update)
    end

    if updated
      set_preservation_modified_time(element)
    end

    element.save
  end

  # Updates the preservation import state and details for a given element.
  # The preservation import state is expected to be among the Constants::PRESERVATION_IMPORT_STATES, a warning will be issued if not.
  # @param metadata The hash with preservation import response metadata to be updated.
  # @param element The element to has its preservation import state updated.
  # @return Whether the update was successful. Or just false, if no metadata is provided.
  def set_preservation_import_metadata(metadata, element)
    unless (metadata && (!metadata.empty?))
      puts "No metadata for updating element with: #{metadata}"
      return false
    end

    # check date. Do not update, if current date is newer.
    unless (metadata['date'].blank? || metadata['date'] == element.preservationMetadata.import_update_date.first)
      if(element.preservationMetadata.import_update_date.first && element.preservationMetadata.import_update_date.first.to_datetime > metadata['date'].to_datetime)
        puts "Will not update state with an older date than the current"
        return false
      end
      element.preservationMetadata.import_update_date = metadata['date']
    end

    unless (metadata['state'].blank? || metadata['state'] == element.preservationMetadata.import_state.first)
      puts "Undefined preservation import state #{metadata['state']} not among the defined ones: #{PRESERVATION_IMPORT_STATES.keys.to_s}" unless PRESERVATION_IMPORT_STATES.keys.include? metadata['state']
      element.preservationMetadata.import_state = metadata['state']
    end

    unless (metadata['detail'].blank? || metadata['detail'] == element.preservationMetadata.import_details.first)
      element.preservationMetadata.import_details = metadata['detail']
    end

    element.save
  end

  # Updates the preservation collection for a given element (e.g. a basic_files, a instance, a work, etc.)
  # @param collection The name of the preservation collection to update with.
  # @param comment The comment attached to the preservation
  # @param element The element to have its preservation collection changed.
  def set_preservation_collection(collection, comment, element)
    puts "Updating '#{element.to_s}' with preservation collection '#{collection}' and comment '#{comment}'"
    if (collection.blank? || element.preservationMetadata.preservation_collection.first == collection) && (comment.blank? || element.preservationMetadata.preservation_comment.first == comment)
      puts 'Nothing to change for the preservation update'
      return
    end

    # Do not update, if the preservation collection is not among the valid preservation collections in the configuration.
    unless PRESERVATION_CONFIG['preservation_collection'].keys.include? collection
      raise ArgumentError, "The preservation collection '#{collection}' is not amongst the valid ones: #{PRESERVATION_CONFIG["preservation_collection"].keys}"
    end

    set_preservation_modified_time(element)
    element.preservationMetadata.preservation_collection = collection
    element.preservationMetadata.preservation_bitsafety = PRESERVATION_CONFIG['preservation_collection'][collection]['bit_safety']
    element.preservationMetadata.preservation_confidentiality = PRESERVATION_CONFIG['preservation_collection'][collection]['confidentiality']
    element.preservationMetadata.preservation_comment = comment
    element.save
  end

  # Validates whether the preservation_state is allowed to be updated.
  # Checks whether the preservation state is set to not stated.
  # @param state The state to validate.
  def can_update_preservation_state?(state)
    if !state.blank? && state == PRESERVATION_STATE_NOT_STARTED.keys.first
      raise ArgumentError, 'Cannot update preservation state, when preservation has not yet started.'
    end
  end

  # Validates whether the import_state allows updating.
  # Checks whether the preservation import state is set and not stated.
  # @param state The state to validate.
  def can_update_preservation_import_state?(state)
    if !state.blank? && state == PRESERVATION_IMPORT_STATE_NOT_STARTED.keys.first
      raise ArgumentError, 'Cannot update preservation import state, when preservation import has not yet started.'
    end
  end

end
