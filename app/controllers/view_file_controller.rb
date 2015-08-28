# -*- encoding : utf-8 -*-
#Controller for retrieving BasicFile objects from Fedora for display to the front-end
class ViewFileController < ApplicationController

  # Show a file by delivering it
  # Used for retrieving files around the BasicFile controller, and thus around the authorization.
  # @return The file which needs to be shown, with the original filename and mime-type.
  def show
    begin
      @content_file = ContentFile.find(URI.unescape(params[:pid]))
      send_data @content_file.datastreams['content'].content, {:filename => @content_file.original_filename, :type => @content_file.mime_type}
    rescue ActiveFedora::ObjectNotFoundError => obj_not_found
      flash[:error] = t('flashmessage.file_not_found')
      logger.error obj_not_found.to_s
      redirect_to :root
    rescue StandardError => standard_error
      flash[:error] = t('flashmessage.standard_error')
      logger.error standard_error.to_s
      redirect_to :root
    end
  end

  skip_before_filter :verify_authenticity_token, :only => :import_from_preservation

  # Imports a preservation instance.
  # Currently only accepts type: FILE (thus the content of a ContentFile)
  #
  def import_from_preservation
    begin
      if handle_preservation_import(params)
        logger.info "Imported file"
        render status: 200, nothing: true
      else
        logger.info "Failed handling preservation import: #{params}"
        render status: 400, nothing: true
      end
    rescue ActiveFedora::ObjectNotFoundError => obj_not_found
      flash[:error] = t('flashmessage.file_not_found')
      logger.error obj_not_found.to_s
      render status: 410, nothing: true
    rescue StandardError => standard_error
      flash[:error] = t('flashmessage.standard_error')
      logger.error standard_error.to_s
      render status: 400, nothing: true
    end
  end

  private
  # Handle the import of the preservation import HTTP POST
  def handle_preservation_import(params)
    # only support content of ContentFile import
    # TODO implement also metadata import
    if(params['type'] != 'FILE')
      logger.warn 'Can only support type = FILE'
      return false
    end

    # Extract the content file
    cf = ContentFile.find(params['uuid'])

    # Validate that preservation import is allowed
    if cf.import_token.blank?
      logger.warn 'No import token, thus no preservation import expected.'
      return false
    end

    # The post request must deliver a token.
    if params['token'].blank?
      logger.warn "No import token delivered. Expected: #{cf.import_token.blank?}"
      return false
    end

    if cf.import_token != params['token']
      logger.warn "Received import token '#{params['token']}' but expected '#{cf.import_token}'"
      return false
    end

    # Validate timeout
    if cf.import_token_timeout.to_datetime < DateTime.now
      logger.warn 'Token has timed out and is no longer valid.'
      return false
    end

    # Remove the token, so it cannot be used again.
    cf.import_token = nil

    logger.info 'Importing the file from preservation'
    cf.add_file(params['file'])
  end
end