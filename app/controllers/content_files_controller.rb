# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ContentFilesController < ApplicationController

  before_action :set_file, only: [:download, :upload, :update]


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

  def upload
    authorize! :edit, params[:id]
  end

  def update
    authorize! :edit, params[:id]

    uploaded_file = params[:file]

    if uploaded_file.nil?
      flash[:error] = "Der er ikke valgt nogen fil"
      redirect_to work_instance_path(@file.instance.work.first,@file.instance)
    else

      v = Validator::RelaxedTei.new
      msg = v.is_valid_xml_content(uploaded_file.read.force_encoding 'UTF-8')
      uploaded_file.rewind


      if msg.blank?
        @file.update_external_file_content(uploaded_file.read.force_encoding 'UTF-8')
        repo  = Administration::ExternalRepository[@file.instance.external_repository]
        repo.push
        flash[:notice] = 'Filen blev opdaterer'
        redirect_to work_instance_path(@file.instance.work.first,@file.instance)
      else
        flash[:error] = msg
        redirect_to work_instance_path(@file.instance.work.first,@file.instance)
      end
    end
  end

  def set_file
    @file = ContentFile.find(params[:id])
  end
end