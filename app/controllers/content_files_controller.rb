# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ContentFilesController < ApplicationController

  before_action :set_file, only: [:download, :upload, :update, :show, :initiate_import_from_preservation]

  def show
  end

  # Retrieve the content file for a given ContentFile.
  # If a wrong BasicFile-id, then a 404 is returned.
  # If something goes wrong server-side, then a 500 is returned.
  def download
    # TODO: Find out why this is needed, should be handeled in ability.rb
    authorize! :read, URI.unescape(params[:id])
    begin
      send_data @file.content, {:filename => @file.original_filename, :type => @file.mime_type}
    rescue ActiveFedora::ObjectNotFoundError => obj_not_found
      flash[:error] = t('content_file.flashmessage.basic_file_not_found')
      logger.error obj_not_found.to_s
      render text: obj_not_found.to_s, status: 404
    rescue => standard_error
      flash[:error] = t('flashmessage.standard_error')
      logger.error "standard error"
      logger.error standard_error.inspect
      render text: standard_error.to_s, status: 500
    end
  end

  def upload
    authorize! :edit, URI.unescape(params[:id])
  end

  def update
    authorize! :edit, URI.unescape(params[:id])

    uploaded_file = params[:file]

    if uploaded_file.nil?
      #this message is not really used, as we handle this case in the _upload_file_modal.html.erb
      flash[:error] = t('content_file.flashmessage.no_file_to_upload')
      redirect_to work_instance_path(@file.instance.work,@file.instance)
    else

      v = Validator::RelaxedTei.new
      msg = v.is_valid_xml_content(uploaded_file.read.force_encoding 'UTF-8')
      uploaded_file.rewind


      if msg.blank?
        @file.update_external_file_content(uploaded_file.read.force_encoding 'UTF-8')
        unless Administration::ExternalRepository[@file.instance.external_repository].nil?
          repo  = Administration::ExternalRepository[@file.instance.external_repository]
          repo.push
        end
        flash[:notice] = t('content_file.flashmessage.file_uploaded')
        redirect_to work_instance_path(@file.instance.work,@file.instance)
      else
        flash[:error] = msg
        redirect_to work_instance_path(@file.instance.work,@file.instance)
      end
    end
  end

  def set_file
    @file = ContentFile.find(URI.unescape(params[:id]))
  end

  def initiate_import_from_preservation
    if @file.send_request_to_import(params['type'])
      flash[:notice] = t('content_file.flashmessage.initiated_import_from_preservation')
      # It only creates a new job, if no such job already exists.
      ReceiveResponsesFromPreservationJob.schedule_new_job
    else
      flash[:notice] = t('content_file.flashmessage.initiated_import_from_preservation_failed')
      flash[:error] = @file.errors.full_messages.to_sentence
    end
    redirect_to @file
  end
end