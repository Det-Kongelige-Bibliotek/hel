module Administration
  class ControlledListsController < ApplicationController
    before_action :set_controlled_list, only: [:show, :edit, :update, :destroy]

    #authorize_resource

    # GET /controlled_lists
    def index
      @controlled_lists = ControlledList.all
    end

    # GET /controlled_lists/1
    def show
    end

    # GET /controlled_lists/new
    def new
      @controlled_list = ControlledList.new
    end

    # GET /controlled_lists/1/edit
    def edit
    end

    # POST /controlled_lists
    def create
      @controlled_list = ControlledList.new(controlled_list_params)

      if @controlled_list.save
        redirect_to @controlled_list, notice: 'ControlledList was successfully created.'
      else
        render action: 'new'
      end
    end

    # PATCH/PUT /controlled_lists/1
    def update
      if @controlled_list.update(controlled_list_params)
        redirect_to @controlled_list, notice: 'ControlledList was successfully updated.'
      else
        render action: 'edit'
      end
    end

    # DELETE /controlled_lists/1
    def destroy
      @controlled_list.delete
      redirect_to administration_controlled_lists_url, notice: 'ControlledList was successfully destroyed.'
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_controlled_list
      @controlled_list = ControlledList[params[:id]]
    end

    # Only allow a trusted parameter "white list" through.
    def controlled_list_params
      puts params
      params.require(:controlled_list).permit(:name)
    end
  end
end