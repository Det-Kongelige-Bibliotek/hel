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
      format.rdf { render rdf: @work }
    end
  end

  # GET /works/new
  def new
    @work = Work.new
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
        format.html { redirect_to @work, notice: 'Værket blev oprettet.' }
        format.json { render :show, status: :created, location: @work }
      else
        format.html { render :new }
        format.json { render json: @work.errors, status: :unprocessable_entity }
      end
    end
  end

  def aleph
    service = AlephService.new
    # :field, :value read as aleph_params["field"] and aleph_params["value"],
    # respectively. 
    # For testing: knausgård is isbn=9788711396322

    query = "#{aleph_params['field']}=#{aleph_params['value']}"
    set = service.find_set(query)
    rec = service.get_record(set[:set_num],set[:num_entries])
    converter = ConversionService.new(rec)
    doc = converter.to_mods('')
    mods = Datastreams::Mods.from_xml(doc) 

    @work=Work.new
    @work.from_mods(mods)

    if @work.save 
      flash[:notice] = 'Værket blev initialiseret med data fra Aleph'
      redirect_to new_work_trykforlaeg_path work_id: @work.pid, query: query
    else
      flash[:error] = 'Det var umuligt at få data fra Aleph'
      redirect_to new_work_path
    end

  end

  # PATCH/PUT /works/1
  # PATCH/PUT /works/1.json
  def update
    respond_to do |format|
      if @work.update(work_params)
        format.html { redirect_to @work, notice: 'Værket er opdateret.' }
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
      format.html { redirect_to works_url, notice: 'Værket blev slettet.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_work
    @work = Work.find(params[:id])
  end

  # special whitelist for when we're importing from Aleph
  def aleph_params
    params.require(:aleph).permit(:field, :value)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def work_params
    params[:work].permit(titles: [[:value, :subtitle, :lang, :type]], creators: [[:id, :type]],note:[])
  end
end
