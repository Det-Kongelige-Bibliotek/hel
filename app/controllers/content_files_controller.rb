# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ContentFilesController < ApplicationController

  before_action :set_file, only: [:download]


  # Retrieve the content file for a given ContentFile.
  # If a wrong BasicFile-id, then a 404 is returned.
  # If something goes wrong server-side, then a 500 is returned.
  def download
    # TODO: Find out why this is needed, should be handeled in ability.rb
    authorize! :read, params[:id]
    begin
      send_data @file.datastreams['content'].content, {:filename => @file.original_filename, :type => @file.mime_type}
    rescue ActiveFedora::ObjectNotFoundError => obj_not_found
      flash[:error] = 'The basic_files you requested could not be found in Fedora! Please contact your system administrator'
      logger.error obj_not_found.to_s
      render text: obj_not_found.to_s, status: 404
    rescue => standard_error
      flash[:error] = 'An error has occurred. Please contact your system administrator'
      logger.error "standard error"
      logger.error standard_error.inspect
      render text: standard_error.to_s, status: 500
    end
  end

  def set_file
    @file = ContentFile.find(params[:id])
  end
end