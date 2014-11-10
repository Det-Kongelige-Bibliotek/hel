# Perform actions on Instances
class InstancesController < ApplicationController
  include PreservationHelper
  before_action :set_work, only: [:create]
  before_action :set_klazz, only: [:index, :new, :create, :update]
  before_action :set_instance, only: [:show, :edit, :update, :destroy,
  :update_preservation_profile, :update_administration]

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
    @instance.work = @work
  end

  # GET /instances/1/edit
  def edit
  end

  # POST /instances
  # POST /instances.json
  def create
      @instance = @klazz.new(instance_params)
      if @instance.save
        flash[:notice] = "#{@klazz} was successfully saved"
      else
        @instance.work = @work
      end
      respond_with(@work, @instance)
  end

  # PATCH/PUT /instances/1
  # PATCH/PUT /instances/1.json
  def update
    flash[:notice] = "#{@klazz} was successfully updated." if @instance.update(instance_params)
    respond_with(@instance.work, @instance)
  end

  # Updates the preservation profile metadata.
  def update_preservation_profile
    begin
      notice = update_preservation_profile_from_controller(params, @instance)
      redirect_to @instance, notice: notice
    rescue => error
      error_msg = "Could not update preservation profile: #{error.inspect}"
      error.backtrace.each do |l|
        error_msg += "\n#{l}"
      end
      logger.error error_msg
      @instance.errors[:preservation] << error.inspect.to_s
      render action: 'preservation'
    end
  end

  def preservation
    @instance = Instance.find(params[:id])
  end

  # DELETE /instances/1
  def destroy
    @instance.destroy
    @instances = @klazz.all
    flash[:notice] = "#{@klazz} was successfully deleted"
    redirect_to action: :index
  end

  # Updates the administration metadata for the ordered instance.
  def update_administration
    begin
      update_administrative_metadata_from_controller(params, @instance, false)
      redirect_to @instance, notice: 'Updated the administrative metadata'
    rescue => error
      error_msg = "Could not update administrative metadata: #{error.inspect}"
      error.backtrace.each do |l|
        error_msg += "\n#{l}"
      end
      logger.error error_msg
      @instance.errors[:administrative_metadata] << error.inspect.to_s
      render action: 'administration'
    end
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
                                     :access_condition, :availability, :collection, :content_files,
                                     :preservation_profile, :set_work, language: [[:value, :part]], note: []
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
