# Perform actions on Instances
class InstancesController < ApplicationController
  include PreservationHelper
  include Concerns::RemoveBlanks
  before_action :set_work, only: [:new, :create, :send_to_preservation]
  before_action :set_klazz, only: [:index, :new, :create, :update]
  before_action :set_instance, only: [:show, :edit, :update, :destroy,
  :send_to_preservation, :update_administration, :validate_tei]

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
      format.xml
    end
  end

  # GET /instances/new
  # We presume that this method is being called remotely
  # so don't render layout.
  # If work_id is given in the params, add this to the object.
  def new
    @instance = @klazz.new
    # TODO: Refactor to use ConversionService.instance_from_aleph
    if params[:query]
      service = AlephService.new
      query = params[:query] 
      set=service.find_set(query) 
      rec=service.get_record(set[:set_num],set[:num_entries])
      converter=ConversionService.new(rec)
      doc = converter.to_mods("")
      mods = Datastreams::Mods.from_xml(doc) 
      if @instance.from_mods(mods)
        flash[:notice] = t('instances.flashmessage.ins_data_retrieved')
      else
        flash[:error]  = t('instances.flashmessage.no_ins_data_retrieved')
      end
    end
    @instance.work = @work
  end

  # GET /instances/1/edit
  def edit
  end

  # POST /instances
  # POST /instances.json
  def create
      @instance = @klazz.new(instance_params)
      @instance.work = @work
      if @instance.save
        flash[:notice] = t('instances.flashmessage.ins_saved', var: @klazz)
        @instance.cascade_preservation_collection
      else
        flash[:notice] = t('instances.flashmessage.ins_saved_fail', var: @klazz)
      end
      respond_with(@work, @instance)
  end

  # PATCH/PUT /instances/1
  # PATCH/PUT /instances/1.json
  def update
    instance_params['activity'] = @instance.activity unless current_user.admin?
    if @instance.update(instance_params)
      # TODO: TEI specific logic should be in an after_save hook rather than on the controller
      if @instance.type == 'TEI' && Administration::Activity.where(id: @instance.activity).first.is_adl_activity?
        @instance.content_files.each do |f|
          # TODO - make this also work for internally managed TEI files
          if f.external_file_path
            TeiHeaderSyncService.perform(File.join(Rails.root,'app','services','xslt','tei_header_update.xsl'),
                                         f.external_file_path,@instance)
            f.update_tech_metadata_for_external_file
            f.save(validate: false)
          end
        end
        repo = Administration::ExternalRepository[@instance.external_repository]
        repo.push if repo.present?
      end
      flash[:notice] = t('instances.flashmessage.ins_updated', var: @klazz)
      @instance.cascade_preservation_collection
    else
    end
    respond_with(@instance.work, @instance)
  end

  def send_to_preservation
    if @instance.content_files().present? && @instance.send_to_preservation
      flash[:notice] = t('instances.flashmessage.preserved')
    elsif @instance.content_files().empty?
      flash[:notice] = t('instances.flashmessage.no_file')
    else
      flash[:notice] = t('instances.flashmessage.no_preserved')
    end
    redirect_to work_instance_path(@instance.work, @instance)
  end

  # DELETE /instances/1
  def destroy
    @instance.destroy
    @instances = @klazz.all
    flash[:notice] = t('instances.flashmessage.destroy', var: @klazz)
    redirect_to action: :index
  end

  # Updates the administration metadata for the ordered instance.
  def update_administration
    begin
      update_administrative_metadata_from_controller(params, @instance, false)
      redirect_to @instance, notice: t('instances.flashmessage.admin_updated')
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

  def validate_tei
    @instance.validation_message = ['Vent Venligst ...']
    @instance.validation_status = 'INPROGRESS'
    @instance.save(validate:false)
    Resque.enqueue(ValidateAdlTeiInstance,@instance.pid)
    redirect_to work_instance_path(@instance.work, @instance)
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
    @instance = @klazz.find(URI.unescape(params[:id]))
  end

  def set_work
    @work = Work.find(URI.unescape(params[:work_id]))
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # Need to do some checking to get rid of blank params here.
  def instance_params
    params.require(@klazz.to_s.downcase.to_sym).permit(:type, :activity, :title_statement, :extent, :copyright,
                                     :dimensions, :mode_of_issuance, :isbn13,
                                     :contents_note, :embargo, :embargo_date, :embargo_condition,
                                     :publisher, :published_date, :copyright_holder, :copyright_date, :copyright_status,
                                     :access_condition, :availability, :preservation_collection, :note, collection: [],
                                     content_files: [], relators_attributes: [[ :id, :agent_id, :role ]],
                                     publications_attributes: [[:id, :copyright_date, :provider_date ]]
    ).tap { |elems| remove_blanks(elems) }
  end


end
