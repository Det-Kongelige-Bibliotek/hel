# Perform actions on Instances
class InstancesController < ApplicationController
  include PreservationHelper
  before_action :set_instance, only: [:show, :edit, :update, :destroy]

  # GET /instances
  # GET /instances.json
  def index
    @instances = Instance.all
  end

  # GET /instances/1
  # GET /instances/1.json
  def show
  end

  # GET /instances/new
  def new
    @instance = Instance.new
  end

  # GET /instances/1/edit
  def edit
  end

  # POST /instances
  # POST /instances.json
  def create
    @instance = Instance.new(instance_params)

    respond_to do |format|
      if @instance.save
        format.html { redirect_to @instance, notice: 'Instance was successfully created.' }
        format.json { render :show, status: :created, location: @instance }
      else
        format.html { render :new }
        format.json { render json: @instance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /instances/1
  # PATCH/PUT /instances/1.json
  def update
    respond_to do |format|
      if @instance.update(instance_params)
        format.html { redirect_to @instance, notice: 'Instance was successfully updated.' }
        format.json { render :show, status: :ok, location: @instance }
      else
        format.html { render :edit }
        format.json { render json: @instance.errors, status: :unprocessable_entity }
      end
    end
  end

  # Updates the preservation profile metadata.
  def update_preservation_profile
    @instance = Instance.find(params[:id])
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
  # DELETE /instances/1.json
  def destroy
    @instance.destroy
    respond_to do |format|
      format.html { redirect_to instances_url, notice: 'Instance was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # Updates the administration metadata for the ordered instance.
  def update_administration
    @instance = Instance.find(params[:id])
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

  # Use callbacks to share common setup or constraints between actions.
  def set_instance
    @instance = Instance.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def instance_params
    params[:instance]
  end
end
