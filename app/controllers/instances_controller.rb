# Perform actions on Instances
class InstancesController < ApplicationController
  include PreservationHelper
  before_action :set_work, only: [:create, :send_to_preservation]
  before_action :set_klazz, only: [:index, :new, :create, :update]
  before_action :set_instance, only: [:show, :edit, :update, :destroy,
  :send_to_preservation, :update_administration, :check_tei_images]

  authorize_resource :work
  authorize_resource :instance, :through => :work

  respond_to :html
  # GET /instances
  # GET /instances.json
  def index
    @instances = @klazz.all
  end

  # GET /instances/1
  # GET /instances/1.json
  def show
    respond_to do |format|
      format.html
      format.rdf { render rdf: @instance }
      format.mods { render mods: @instance }
    end
  end

  # GET /instances/new
  # We presume that this method is being called remotely
  # so don't render layout.
  # If work_id is given in the params, add this to the object.
  def new
    @instance = @klazz.new
    @work = Work.find(params[:work_id])
    if params[:query] 
      service = AlephService.new
      query = params[:query] 
      set=service.find_set(query) 
      rec=service.get_record(set[:set_num],set[:num_entries])
      converter=ConversionService.new(rec)
      doc = converter.to_mods("")
      mods = Datastreams::Mods.from_xml(doc) 
      if @instance.from_mods(mods)
        flash[:notice] = "Instans data er hentet."
      else
        flash[:error]  = "Kunne ikke hente instans data."
      end
    end
    @instance.work << @work
  end

  # GET /instances/1/edit
  def edit
  end

  # POST /instances
  # POST /instances.json
  def create
      @instance = @klazz.new(instance_params)
      if @instance.save
        flash[:notice] = "#{@klazz} blev gemt"
        @instance.cascade_preservation
      else
        @instance.work << @work
      end
      respond_with(@work, @instance)
  end

  # PATCH/PUT /instances/1
  # PATCH/PUT /instances/1.json
  def update
    instance_params['activity'] = @instance.activity unless current_user.admin?
    if @instance.update(instance_params)
      flash[:notice] = "#{@klazz} er opdateret."
      @instance.cascade_preservation
    end
    respond_with(@instance.work.first, @instance)
  end

  def send_to_preservation
    if @instance.send_to_preservation
      flash[:notice] = 'Instans og indholdsfiler sendt til bevaring'
    else
      flash[:notice] = 'Kunne ikke send til bevaring'
    end
    redirect_to work_instance_path(@instance.work.first,@instance)
  end

  # DELETE /instances/1
  def destroy
    @instance.destroy
    @instances = @klazz.all
    flash[:notice] = "#{@klazz} er slettet"
    redirect_to action: :index
  end

  # Updates the administration metadata for the ordered instance.
  def update_administration
    begin
      update_administrative_metadata_from_controller(params, @instance, false)
      redirect_to @instance, notice: 'Administrativ metadata er opdateret'
    rescue => error
      error_msg = "Kunne ikke opdatere administrativ metadata: #{error.inspect}"
      error.backtrace.each do |l|
        error_msg += "\n#{l}"
      end
      logger.error error_msg
      @instance.errors[:administrative_metadata] << error.inspect.to_s
      render action: 'administration'
    end
  end

  def check_tei_images
    v = Validator::TeiImagesFound.new
    v.validate @instance
    render :json => {:errors => @instance.errors.full_messages }
  end

  private

  # This helper method enables controller subclassing
  def set_klazz
    @klazz = Instance
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_instance
    set_klazz if @klazz.nil?
    set_work if @work.nil? && params[:work_id].present?
    @instance = @klazz.find(params[:id])
  end

  def set_work
    @work = Work.find(params[:work_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # Need to do some checking to get rid of blank params here.
  def instance_params
    params.require(@klazz.to_s.downcase.to_sym).permit(:activity, :title_statement, :extent, :copyright,  
                                     :copyright_date, :published_date, :dimensions, :mode_of_issuance, :isbn13,
                                     :contents_note, :embargo, :embargo_date, :embargo_condition,
                                     :access_condition, :availability, :collection, :preservation_profile,
                                     :set_work, language: [[:value, :part]], note: [], content_files: []
    ).tap { |elems| remove_blanks(elems) }
  end

  # Remove any blank attribute values, including those found in Arrays and Hashes
  # to prevent AF being updated with empty values.
  def remove_blanks(param_hash)
    param_hash.each do |k, v|
      if v.is_a? String
        param_hash.delete(k) unless v.present?
      elsif v.is_a? Array
        param_hash[k] = v.reject(&:blank?)
      elsif v.is_a? Hash
        param_hash[k] = remove_blanks(v)
        param_hash.delete(k) unless param_hash[k].present?
      end
    end
    param_hash
  end
end
