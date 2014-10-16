module Authority
  # Provide default functionality for inheritance by
  # concrete Authority classes
  class BasesController < ApplicationController
    before_action :set_object, only: [:show, :edit, :update, :destroy]
    before_action :set_klazz, only: [:index, :new, :create]
    # GET /authority/bases
    # GET /authority/bases.json
    def index
      @authority_bases = @klazz.descendants
    end

    # GET /authority/bases/1
    # GET /authority/bases/1.json
    def show
    end

    # GET /authority/bases/new
    def new
      @authority_object = @klazz.new
    end

    # GET /authority/bases/1/edit
    def edit
    end

    # POST /authority/bases
    # POST /authority/bases.json
    def create
      @authority_object = @klazz.new(authority_base_params)

      respond_to do |format|
        if @authority_object.save
          format.html { redirect_to @authority_object, notice: 'Base was successfully created.' }
          format.json { render :show, status: :created, location: @authority_object }
        else
          format.html { render :new }
          format.json { render json: @authority_object.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /authority/bases/1
    # PATCH/PUT /authority/bases/1.json
    def update
      respond_to do |format|
        if @authority_object.update(authority_base_params)
          format.html { redirect_to @authority_object, notice: 'Base was successfully updated.' }
          format.json { render :show, status: :ok, location: @authority_object }
        else
          format.html { render :edit }
          format.json { render json: @authority_object.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /authority/bases/1
    # DELETE /authority/bases/1.json
    def destroy
      @authority_object.destroy
      respond_to do |format|
        format.html { redirect_to authority_bases_url, notice: 'Base was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_object
      @authority_object = ActiveFedora::Base.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def authority_base_params
      params[:authority_object]
    end

    def set_klazz
      @klazz = Authority::Base
    end
  end
end
