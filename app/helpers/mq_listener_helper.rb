# -*- encoding : utf-8 -*-

include PreservationHelper

# Provides methods for all elements for sending a message over RabbitMQ
module MqListenerHelper
  # Handles the preservation response messages
  # @param message The message in JSON format.
  def handle_preservation_response(message)
    puts "handle preservation response #{message}"
    if message['id'].blank? || message['model'].blank? || message['preservation'].nil?
      puts "Invalid preservation response message: #{message}"
      return false
    end

    element = find_element(message['id'], message['model'])
    puts "Updating preservation metadata for: #{element}"
    update_preservation_metadata_for_element(message, element)
  end

  def handle_preservation_import_response(message)
    if message['uuid'].blank? || message['type'].blank? || message['response'].nil?
      puts "Invalid preservation import response message: #{message}"
      return false
    end
    # TODO handle only FILE types
    if message['type'] != 'FILE'
      puts "Can only handle FILE type, not #{message['type']}"
      return false
    end

    element = ContentFile.find(message['uuid'])
    puts "Updating preservation import metadata for: #{element}"
    update_preservation_import_metadata_for_element(message, element)
  end

  private
  # Locates a given element based on its model and id.
  # If no model matches the element, then an error is raised.
  # @param id The id of the element to look up.
  # @param model The model of the element to look up.
  # @return The element with the given id and the given model.
  def find_element(id, model)
    case model.downcase
      when 'work'
        return Work.find(id)
      when 'contentfile'
        return ContentFile.find(id)
      when 'instance'
        return Instance.find(id)
      else
        raise "Unknown element type #{model}"
    end
  end
end