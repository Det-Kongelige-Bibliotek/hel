# -*- coding: utf-8 -*-
# Handle actions on Works
class WorksController < ApplicationController
  before_action :set_work, only: [:show, :edit, :update, :destroy]
  authorize_resource

  # GET /works
  # GET /works.json
  def index
    @works = Work.all
  end

  # GET /works/1
  # GET /works/1.json
  def show
    respond_to do |format|
      format.html
    end
  end

  # GET /works/new
  def new
    @work = Work.new
    @work.titles.build
    @work.relators.build
  end

  # GET /works/1/edit
  def edit
  end

  # POST /works
  # POST /works.json
  def create
    @work = Work.new(work_params)

    respond_to do |format|
      if @work.save
        format.html { redirect_to @work, notice: t('work.save') }
        format.json { render :show, status: :created, location: @work }
      else
        @work.titles.build
        @work.relators.build unless @work.relators.present?
        format.html { render :new }
        format.json { render json: @work.errors, status: :unprocessable_entity }
      end
    end
  end

  # For testing: knausgård is isbn=9788711396322
  def aleph
    @work = ConversionService.work_from_aleph(aleph_params['field'], aleph_params['value'])
    if @work.present?
      if @work.save
        flash[:notice] = I18n.t('work.aleph.success_message')
        query =  "#{aleph_params[:field]}=#{aleph_params[:value]}"
        redirect_to new_work_instance_path work_id: @work.pid, query: query and return
      else
        error = I18n.t('work.save_error')
      end
    else
      error = I18n.t('work.aleph.error_message', field: aleph_params['field'], value: aleph_params['value'])
    end
    flash[:error] = error
    redirect_to new_work_path
  end

  # PATCH/PUT /works/1
  # PATCH/PUT /works/1.json
  def update
    respond_to do |format|
      if @work.update(work_params)
        @work.instances.each do |i|
          if i.type == 'TEI' && i.activity.present? && Administration::Activity.where(id: i.activity).first.is_adl_activity?
            i.content_files.each do |f|
                logger.debug("staring TEI sync")
                TeiHeaderSyncService.perform(File.join(Rails.root,'app','services','xslt','tei_header_update.xsl'),
                f.external_file_path,i)
                logger.debug("done")
                f.update_tech_metadata_for_external_file
                f.save(validate: false)
            end
            repo = Administration::ExternalRepository[i.external_repository]
            repo.push unless repo.nil?
          end
        end
        format.html { redirect_to @work, notice: t('work.update') }
        format.json { render :show, status: :ok, location: @work }
      else
        format.html { render :edit }
        format.json { render json: @work.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /works/1
  # DELETE /works/1.json
  def destroy
    @work.destroy
    respond_to do |format|
      format.html { redirect_to works_url, notice: t('work.destroy') }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_work
    @work = Work.find(URI.unescape(params[:id]))
  end

  # special whitelist for when we're importing from Aleph
  def aleph_params
    params.require(:aleph).permit(:field, :value)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def work_params
    params[:work].permit(:language, :origin_date, titles_attributes: [[:id, :value, :subtitle, :lang, :type, :_destroy]],
                         relators_attributes: [[ :id, :agent_id, :role, :_destroy ]], subjects: [[:id]], note:[]).tap do |fields|
      # remove any inputs with blank values
      fields['titles_attributes'] = fields['titles_attributes'].select {|k,v| v['value'].present? && (v['id'].present? || v['_destroy'] != '1')} if fields['titles_attributes'].present?

      #remove any agents whit blank agent_id
      #remove any agents whith no relator_id and destroy set to true (this happens when a user has added a relator in the interface
      # and deleted it again before saving)
      fields['relators_attributes'] = fields['relators_attributes'].select {|k,v| v['agent_id'].present? && (v['id'].present? || v['_destroy'] != '1')} if fields['relators_attributes'].present?
    end
  end
end
